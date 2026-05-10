import glob
extra = [
    ("Ãšltimos", "Ultimos"),
    ("Ãšltimo", "Ultimo"),
    ("Ã—", "x"),
    ("Ã\x97", "x"),
]
files = glob.glob("web/src/pages/*.tsx") + glob.glob("web/src/ui/*.tsx")
for f in files:
    c = open(f, encoding="utf-8").read()
    o = c
    for b, g in extra:
        c = c.replace(b, g)
    if c != o:
        open(f, "w", encoding="utf-8").write(c)
        print("Fixed:", f)
print("done")

