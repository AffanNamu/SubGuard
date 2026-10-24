"""Trains the small digit network that UniMarkLy runs on the phone.

    python3 tool/train/train_digits.py            # trains, evaluates, exports

What it makes (all reproducible from this script and a fixed seed):
  assets/models/digits_v1.bin            float32 weights, little-endian, fixed order
  assets/models/digits_v1.manifest.json  checksum, size, training data, measured results
  test/fixtures/digit_model_parity.json  inputs and outputs, to check the Dart code matches
  test/fixtures/digits_eval.json         held-out characters for the accuracy test

Training data: MNIST only (60,000 digits, written by US census staff and students),
with heavy augmentation meant to look like pen on exam paper (thinner and
thicker strokes, slant, blur, grain, ruled lines through the digit, broken
strokes) plus a "not a digit" class made from scribbles, fragments and noise.

What this does NOT show: how well it reads Nigerian university examiners'
handwriting. That needs labelled examples from real booklets, which the app can
export once examiners have confirmed marks (docs/recognition/DATASET.md).
"""
import base64, gzip, hashlib, json, os, struct, sys, urllib.request
import numpy as np
import torch, torch.nn as nn, torch.nn.functional as F

SEED = 20261024
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
CACHE = os.environ.get("MNIST_DIR", "/tmp/mnist")
torch.manual_seed(SEED)
np.random.seed(SEED)
torch.set_num_threads(os.cpu_count() or 4)

URLS = ["https://ossci-datasets.s3.amazonaws.com/mnist/", "https://storage.googleapis.com/cvdf-datasets/mnist/"]
FILES = ["train-images-idx3-ubyte.gz", "train-labels-idx1-ubyte.gz", "t10k-images-idx3-ubyte.gz", "t10k-labels-idx1-ubyte.gz"]


def fetch(name):
    os.makedirs(CACHE, exist_ok=True)
    path = os.path.join(CACHE, name)
    if not os.path.exists(path):
        for base in URLS:
            try:
                urllib.request.urlretrieve(base + name, path)
                break
            except Exception as e:
                print("failed", base, e)
        else:
            sys.exit("could not download " + name)
    return path


def read_images(path):
    with gzip.open(path) as f:
        _, n, r, c = struct.unpack(">IIII", f.read(16))
        return np.frombuffer(f.read(), np.uint8).reshape(n, r, c)


def read_labels(path):
    with gzip.open(path) as f:
        f.read(8)
        return np.frombuffer(f.read(), np.uint8)


# ----------------------------------------------------------------- model ----
class Net(nn.Module):
    """Mirrors lib/services/vision/digit_model.dart exactly."""

    def __init__(self):
        super().__init__()
        self.c1 = nn.Conv2d(1, 12, 5)
        self.c2 = nn.Conv2d(12, 24, 5)
        self.f1 = nn.Linear(24 * 4 * 4, 64)
        self.f2 = nn.Linear(64, 11)

    def forward(self, x):
        x = F.max_pool2d(F.relu(self.c1(x)), 2)
        x = F.max_pool2d(F.relu(self.c2(x)), 2)
        x = x.flatten(1)
        return self.f2(F.relu(self.f1(x)))


# ---------------------------------------------------------- augmentation ----
def affine(x, rot=15, shear=0.3, scale=(0.7, 1.2), shift=3):
    n = x.shape[0]
    a = (torch.rand(n) * 2 - 1) * rot * np.pi / 180
    sh = (torch.rand(n) * 2 - 1) * shear
    sc = torch.empty(n).uniform_(*scale)
    tx = (torch.rand(n) * 2 - 1) * shift / 14
    ty = (torch.rand(n) * 2 - 1) * shift / 14
    cos, sin = torch.cos(a) / sc, torch.sin(a) / sc
    theta = torch.stack([torch.stack([cos, -sin + sh, tx], 1), torch.stack([sin, cos, ty], 1)], 1)
    grid = F.affine_grid(theta, x.shape, align_corners=False)
    return F.grid_sample(x, grid, padding_mode="zeros", align_corners=False)


def thickness(x):
    """Thin or thicken strokes: pen width varies much more than MNIST's."""
    n = x.shape[0]
    mode = torch.randint(0, 3, (n,))
    thick = F.max_pool2d(x, 3, 1, 1)
    thin = -F.max_pool2d(-x, 3, 1, 1)
    out = x.clone()
    out[mode == 1] = thick[mode == 1]
    out[mode == 2] = thin[mode == 2]
    return out


def blur(x):
    n = x.shape[0]
    k = torch.tensor([[1, 2, 1], [2, 4, 2], [1, 2, 1]], dtype=torch.float32) / 16
    b = F.conv2d(x, k.view(1, 1, 3, 3), padding=1)
    use = (torch.rand(n) < 0.4).view(n, 1, 1, 1)
    return torch.where(use, b, x)


def faint_and_noise(x):
    """Faint ink, grain and a paper-tone offset, each applied to only some pictures.

    A first version applied all three to every picture, so the network never saw
    a clean digit on a perfectly black background and read 27% of clean MNIST as
    "not a digit". The ink maps the app produces do have exactly that clean
    background, so the clean case must be well represented: the test below fails
    the run if clean accuracy drops.
    """
    n = x.shape[0]
    faint = (torch.rand(n, 1, 1, 1) < 0.7).float()
    gain = 1 - faint * torch.empty(n, 1, 1, 1).uniform_(0, 0.55)  # 1.0 down to 0.45
    x = x * gain
    sigma = torch.empty(n, 1, 1, 1).uniform_(0, 0.12) * (torch.rand(n, 1, 1, 1) < 0.5)
    x = x + torch.randn_like(x) * sigma
    base = torch.empty(n, 1, 1, 1).uniform_(0, 0.08) * (torch.rand(n, 1, 1, 1) < 0.5)
    return (x + base).clamp(0, 1)


def ruled_lines(x):
    """A pen-coloured line through the digit, as a table border or rule does."""
    n = x.shape[0]
    out = x.clone()
    for i in torch.nonzero(torch.rand(n) < 0.25).flatten().tolist():
        v = np.random.uniform(0.4, 0.9)
        if np.random.rand() < 0.5:
            r = np.random.randint(2, 26)
            out[i, 0, r, :] = torch.maximum(out[i, 0, r, :], torch.tensor(v))
        else:
            c = np.random.randint(2, 26)
            out[i, 0, :, c] = torch.maximum(out[i, 0, :, c], torch.tensor(v))
    return out


def broken_strokes(x):
    n = x.shape[0]
    out = x.clone()
    for i in torch.nonzero(torch.rand(n) < 0.18).flatten().tolist():
        for _ in range(np.random.randint(1, 3)):
            r, c = np.random.randint(4, 24, 2)
            out[i, 0, r : r + 2, c : c + 2] = 0
    return out


def augment(x):
    n = x.shape[0]
    moved = affine(x)
    use = (torch.rand(n) < 0.85).view(n, 1, 1, 1)
    x = torch.where(use, moved, x)
    x = thickness(x)
    x = blur(x)
    x = broken_strokes(x)
    x = ruled_lines(x)
    return faint_and_noise(x)


def junk(n):
    """The 'not a digit' class: scribbles, lines, blobs, fragments and grain."""
    out = np.zeros((n, 28, 28), np.float32)
    for i in range(n):
        kind = np.random.randint(0, 5)
        img = np.zeros((28, 28), np.float32)
        if kind == 0:  # scribble
            p = np.random.uniform(5, 23, 2)
            for _ in range(np.random.randint(3, 9)):
                q = np.clip(p + np.random.normal(0, 7, 2), 2, 25)
                for t in np.linspace(0, 1, 30):
                    x, y = (p * (1 - t) + q * t).astype(int)
                    img[max(0, y - 1) : y + 1, max(0, x - 1) : x + 1] = 1
                p = q
        elif kind == 1:  # a lone line
            if np.random.rand() < 0.5:
                r = np.random.randint(4, 24)
                a, b = sorted(np.random.randint(0, 28, 2))
                img[r : r + 2, a : max(a + 6, b)] = 1
            else:
                c = np.random.randint(4, 24)
                a, b = sorted(np.random.randint(0, 28, 2))
                img[a : max(a + 6, b), c : c + 2] = 1
        elif kind == 2:  # a blob
            cx, cy = np.random.uniform(8, 20, 2)
            r = np.random.uniform(2, 9)
            yy, xx = np.mgrid[:28, :28]
            img = (((xx - cx) ** 2 + (yy - cy) ** 2) < r * r).astype(np.float32) * np.random.uniform(0.5, 1)
        elif kind == 3:  # grain
            img = (np.random.rand(28, 28) < np.random.uniform(0.05, 0.3)).astype(np.float32)
        else:  # mostly-empty corner dust
            r, c = np.random.randint(0, 20, 2)
            img[r : r + 6, c : c + 6] = (np.random.rand(6, 6) < 0.5)
        out[i] = img
    return torch.from_numpy(out).unsqueeze(1)


def fragments(x):
    """Half or more of a real digit cut away: not enough left to read."""
    out = x.clone()
    for i in range(x.shape[0]):
        keep = np.random.uniform(0.15, 0.4)
        if np.random.rand() < 0.5:
            cut = int(28 * keep)
            if np.random.rand() < 0.5:
                out[i, 0, cut:, :] = 0
            else:
                out[i, 0, : 28 - cut, :] = 0
        else:
            cut = int(28 * keep)
            if np.random.rand() < 0.5:
                out[i, 0, :, cut:] = 0
            else:
                out[i, 0, :, : 28 - cut] = 0
    return out


# ----------------------------------------------------------------- train ----
def main():
    xtr = torch.from_numpy(read_images(fetch(FILES[0])).astype(np.float32) / 255).unsqueeze(1)
    ytr = torch.from_numpy(read_labels(fetch(FILES[1])).astype(np.int64))
    xte = torch.from_numpy(read_images(fetch(FILES[2])).astype(np.float32) / 255).unsqueeze(1)
    yte = torch.from_numpy(read_labels(fetch(FILES[3])).astype(np.int64))
    perm = torch.randperm(len(xtr))
    val_idx, tr_idx = perm[:5000], perm[5000:]
    xval, yval = xtr[val_idx], ytr[val_idx]
    xtr, ytr = xtr[tr_idx], ytr[tr_idx]
    print("train", len(xtr), "val", len(xval), "test", len(xte))

    net = Net()
    opt = torch.optim.AdamW(net.parameters(), 2e-3, weight_decay=1e-4)
    epochs = int(os.environ.get("EPOCHS", 14))
    sched = torch.optim.lr_scheduler.OneCycleLR(opt, 4e-3, total_steps=epochs * (len(xtr) // 256 + 1))
    for ep in range(epochs):
        net.train()
        order = torch.randperm(len(xtr))
        tot = 0.0
        for s in range(0, len(xtr), 256):
            idx = order[s : s + 256]
            xb, yb = xtr[idx], ytr[idx]
            xb = augment(xb)
            # about 10% "not a digit"
            m = max(1, len(idx) // 10)
            half = m // 2
            xj = torch.cat([junk(m - half), fragments(augment(xtr[order[s : s + half]]))]) if half else junk(m)
            xb = torch.cat([xb, xj])
            yb = torch.cat([yb, torch.full((len(xj),), 10)])
            loss = F.cross_entropy(net(xb), yb, label_smoothing=0.02)
            opt.zero_grad()
            loss.backward()
            opt.step()
            sched.step()
            tot += loss.item() * len(idx)
        net.eval()
        with torch.no_grad():
            torch.manual_seed(SEED + 1)
            va = (net(augment(xval)).argmax(1) == yval).float().mean().item()
            vc = (net(xval).argmax(1) == yval).float().mean().item()
        print(f"epoch {ep + 1:2d}  loss {tot / len(xtr):.4f}  augmented-val acc {va:.4f}  clean-val acc {vc:.4f}")

    # ------------------------------------------------------- evaluation ----
    net.eval()
    torch.manual_seed(SEED + 2)
    np.random.seed(SEED + 2)
    with torch.no_grad():
        clean = (net(xte).argmax(1) == yte).float().mean().item()
        xa = augment(xte)
        aug_pred = net(xa).argmax(1)
        aug = (aug_pred == yte).float().mean().item()
        # confidence-gated: of the digits answered with prob >= 0.9, how many are right?
        p = F.softmax(net(xa), 1)
        conf, pr = p.max(1)
        gate = conf >= 0.9
        gate_cov = gate.float().mean().item()
        gate_acc = (pr[gate] == yte[gate]).float().mean().item()
        xj = junk(5000)
        pj = F.softmax(net(xj), 1)
        rej_recall = (pj.argmax(1) == 10).float().mean().item()
        # false acceptance: a junk picture answered as a digit with prob >= 0.9
        false_accept_junk = ((pj[:, :10].max(1).values >= 0.9)).float().mean().item()
        # most confused pairs under augmentation
        conf_mat = np.zeros((11, 11), int)
        for t, q in zip(yte.numpy(), aug_pred.numpy()):
            conf_mat[t, q] += 1
        pairs = sorted([(conf_mat[i, j], i, j) for i in range(10) for j in range(11) if i != j], reverse=True)[:8]
    results = {
        "mnist_test_clean_accuracy": round(clean, 4),
        "mnist_test_augmented_accuracy": round(aug, 4),
        "augmented_answered_at_p>=0.9": {"coverage": round(gate_cov, 4), "accuracy_when_answered": round(gate_acc, 4)},
        "junk_rejected_as_not_a_digit": round(rej_recall, 4),
        "junk_accepted_as_digit_at_p>=0.9": round(false_accept_junk, 4),
        "most_confused_under_augmentation": [{"true": int(i), "read_as": int(j), "count": int(c)} for c, i, j in pairs],
        "test_set": "MNIST test, 10,000 digits (same writers' population as training; not exam handwriting)",
        "augmentation_seed": SEED,
    }
    print(json.dumps(results, indent=1))
    if clean < 0.97:
        sys.exit(f"clean MNIST accuracy {clean:.4f} is below 0.97: not exporting this model")

    # ----------------------------------------------------------- export ----
    w = []
    for t in [net.c1.weight, net.c1.bias, net.c2.weight, net.c2.bias, net.f1.weight, net.f1.bias, net.f2.weight, net.f2.bias]:
        w.append(t.detach().numpy().astype("<f4").ravel())
    blob = np.concatenate(w).tobytes()
    out_dir = os.path.join(ROOT, "assets", "models")
    os.makedirs(out_dir, exist_ok=True)
    with open(os.path.join(out_dir, "digits_v1.bin"), "wb") as f:
        f.write(blob)
    manifest = {
        "id": "unimarkly-digits",
        "version": "1.0.0",
        "file": "digits_v1.bin",
        "format": "float32 little-endian: conv1.w conv1.b conv2.w conv2.b fc1.w fc1.b fc2.w fc2.b",
        "bytes": len(blob),
        "sha256": hashlib.sha256(blob).hexdigest(),
        "architecture": "conv5x5(1->12) relu pool2, conv5x5(12->24) relu pool2, fc 384->64 relu, fc 64->11",
        "classes": "0-9 and 10 = not a digit",
        "input": "28x28, ink=1 paper=0, digit scaled into 20x20 and centred by centre of mass (as MNIST)",
        "licence": "Weights trained by UniMarkLy on MNIST (CC BY-SA 3.0 data, from NIST public-domain originals); the network design is generic. Redistribution: weights may be shipped with the app; attribute MNIST.",
        "training": {"script": "tool/train/train_digits.py", "data": "MNIST train 55,000 (+5,000 validation)", "epochs": epochs, "seed": SEED, "torch": torch.__version__},
        "measured": results,
    }
    json.dump(manifest, open(os.path.join(out_dir, "digits_v1.manifest.json"), "w"), indent=1)

    fx = os.path.join(ROOT, "test", "fixtures")
    os.makedirs(fx, exist_ok=True)
    with torch.no_grad():
        sample = xte[:24]
        probs = F.softmax(net(sample), 1)
    json.dump(
        {"inputs": [base64.b64encode((s[0].numpy() * 255).round().astype(np.uint8).tobytes()).decode() for s in sample],
         "note": "inputs quantised to 8 bits then scaled by 1/255; probabilities computed from the quantised inputs",
         "probabilities": []},
        open(os.path.join(fx, "digit_model_parity.json"), "w"),
    )
    # recompute from the quantised inputs so Dart sees the same numbers
    q = torch.from_numpy(np.stack([np.frombuffer(base64.b64decode(b), np.uint8).reshape(28, 28) for b in json.load(open(os.path.join(fx, "digit_model_parity.json")))["inputs"]]).astype(np.float32) / 255).unsqueeze(1)
    with torch.no_grad():
        pq = F.softmax(net(q), 1).numpy().round(6).tolist()
    d = json.load(open(os.path.join(fx, "digit_model_parity.json")))
    d["probabilities"] = pq
    json.dump(d, open(os.path.join(fx, "digit_model_parity.json"), "w"))

    # held-out evaluation characters: 200 clean + 200 augmented (fixed seed)
    torch.manual_seed(SEED + 3)
    np.random.seed(SEED + 3)
    sel = torch.randperm(len(xte))[:200]
    ec = (xte[sel][:, 0].numpy() * 255).round().astype(np.uint8)
    ea = (augment(xte[sel])[:, 0].numpy() * 255).round().astype(np.uint8)
    json.dump(
        {"clean": {"labels": yte[sel].tolist(), "images": [base64.b64encode(i.tobytes()).decode() for i in ec]},
         "augmented": {"labels": yte[sel].tolist(), "images": [base64.b64encode(i.tobytes()).decode() for i in ea]},
         "source": "MNIST test digits, never used in training; 'augmented' applies the training augmentation"},
        open(os.path.join(fx, "digits_eval.json"), "w"),
    )
    print("wrote", len(blob), "bytes of weights")


if __name__ == "__main__":
    main()
