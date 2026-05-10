c = open('web/src/pages/SalesPage.tsx',encoding='utf-8',errors='replace').read()
bad = [(i,l) for i,l in enumerate(c.split('\n'),1) if '\ufffd' in l or 'â' in l]
for i,l in bad: print(i, repr(l[:120]))
