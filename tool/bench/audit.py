"""Baseline: every candidate recogniser x image-preparation variant on the
ground-truth field boxes of every dataset document.

    python3 tool/bench/audit.py                # prints the table, writes JSON
    python3 tool/bench/audit.py booklet-001    # one document

The boxes come from the annotation, so this measures the *recogniser* alone,
not the layout step that has to find the box.
"""
import json, os, sys, time, collections
sys.path.insert(0, os.path.dirname(__file__))
import bench_lib as B

only = sys.argv[1:] or None
docs = B.load_dataset(only)
engs = B.engines()
rows = []
for d in docs:
    for f in d["fields"]:
        if f["kind"] == "printed_number" and f["key"] != "serial_no":
            continue
        crop = B.field_crop(d, f, pad=0.15)
        for vname, vfun in B.VARIANTS.items():
            img = vfun(crop)
            for e in engs:
                t0 = time.time()
                try:
                    text, conf = e.read(img, f["kind"])
                except Exception as ex:  # an engine failing is a result too
                    text, conf = f"<error {type(ex).__name__}>", 0.0
                s = B.score(f["kind"], f["text"], text)
                rows.append({"doc": d["doc_id"], "field": f["key"], "kind": f["kind"], "truth": f["text"], "variant": vname,
                             "engine": e.name, "read": text, "conf": round(conf, 3), "exact": s["exact"],
                             "cer": round(s["cer"], 3), "ms": round((time.time() - t0) * 1000)})

out = os.path.join(B.ROOT, "docs", "recognition", "results", "audit_baseline.json")
json.dump({"rows": rows}, open(out, "w"), indent=1, ensure_ascii=False)

# --- summary: for every field kind, best exact-match count over variants per engine
print(f"{len(docs)} document(s), {len(rows)} readings\n")
by = collections.defaultdict(list)
for r in rows:
    by[(r["kind"], r["engine"], r["variant"])].append(r)
print(f"{'kind':<20}{'engine':<22}{'variant':<10}{'exact':>7}{'mean CER':>10}{'empty':>7}")
for (kind, eng, var), rs in sorted(by.items()):
    n = len(rs)
    print(f"{kind:<20}{eng:<22}{var:<10}{sum(r['exact'] for r in rs):>3}/{n:<3}{sum(r['cer'] for r in rs)/n:>10.2f}{sum(1 for r in rs if not r['read'].strip()):>7}")
