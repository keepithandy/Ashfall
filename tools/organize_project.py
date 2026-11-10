from pathlib import Path
import shutil,json
r=Path.cwd(); moves={}
for p in r.glob('*.gd'):
 folder='scripts/runtime'
 if p.name.startswith(('bake_','build_')) or p.stem.endswith('_builder'):folder='scripts/authoring'
 elif 'review' in p.stem or 'gallery' in p.stem or p.stem=='inventory_preview':folder='scripts/review'
 moves[p.name]=folder+'/'+p.name
 if p.with_suffix('.gd.uid').exists():moves[p.name+'.uid']=folder+'/'+p.name+'.uid'
for p in r.glob('*.md'):
 if p.name!='README.md':moves[p.name]='docs/notes/'+p.name
for p in r.glob('Inspect *.cmd'):moves[p.name]='tools/launchers/'+p.name
for n in ['preview.png','preview.png.import','ChatGPT Image Nov 6, 2026, 07_48_19 PM.png','ChatGPT Image Nov 6, 2026, 07_48_19 PM.png.import']:
 if (r/n).exists():moves[n]='concept-art/archive/'+n
moves['main.tscn']='scenes/legacy/main.tscn'
for old,new in moves.items():
 dest=r/new;dest.parent.mkdir(parents=True,exist_ok=True)
 if dest.exists():raise RuntimeError('Destination exists: '+new)
 shutil.move(str(r/old),str(dest))
text_ext={'.gd','.tscn','.tres','.godot','.py','.md','.cmd','.json','.cfg','.import'}
for p in r.rglob('*'):
 if not p.is_file() or p.suffix not in text_ext or any(x in p.parts for x in ['.git','.godot','builds']):continue
 try:s=p.read_text(encoding='utf-8-sig')
 except UnicodeError:continue
 original=s
 for old,new in moves.items():s=s.replace('res://'+old,'res://'+new)
 if p.parent==r/'tools/launchers':s=s.replace('%~dp0.', '%~dp0..\\..').replace('%~dp0..\\Godot','%~dp0..\\..\\..\\Godot')
 if s!=original:p.write_text(s,encoding='utf-8')
(r/'docs/cleanup-moves.json').write_text(json.dumps(moves,indent=2))
print('Moved',len(moves),'files and updated resource references')
