import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {fileURLToPath} from 'node:url';
const root=path.dirname(fileURLToPath(import.meta.url));
const project=path.resolve(root,'../..');
const read=p=>JSON.parse(fs.readFileSync(p,'utf8').replace(/^\uFEFF/,''));
const ledger=read(path.join(root,'sources/acquisition.json'));
const inspections=read(path.join(root,'sources/inspection.json'));
const failures=[];
for(const r of ledger){const relative=r.path.split(/[\\/]/).slice(-((r.path.includes('textures')?3:2))).join('/');const file=path.join(root,'sources',relative);if(!fs.existsSync(file)||crypto.createHash('md5').update(fs.readFileSync(file)).digest('hex')!==r.md5)failures.push('Checksum: '+relative);}
let links=0;
for(const file of fs.readdirSync(root).filter(f=>/\.(md|html)$/.test(f))){const text=fs.readFileSync(path.join(root,file),'utf8');const refs=file.endsWith('.md')?[...text.matchAll(/\]\(([^)]+)\)/g)].map(x=>x[1]):[...text.matchAll(/(?:src|href)="([^"]+)"/g)].map(x=>x[1]);for(const ref of refs){if(/^(https?:|#)/.test(ref))continue;links++;if(!fs.existsSync(path.resolve(root,ref)))failures.push(`${file}: ${ref}`);}}
const assets=read(path.join(root,'existing_assets.json'));for(const a of assets)if(!fs.existsSync(path.join(project,a.path)))failures.push('Asset: '+a.path);
const images=fs.readdirSync(root).filter(f=>f.endsWith('.png')).map(f=>{const b=fs.readFileSync(path.join(root,f));if(b.subarray(0,8).toString('hex')!=='89504e470d0a1a0a')failures.push('PNG: '+f);return {file:f,width:b.readUInt32BE(16),height:b.readUInt32BE(20),sha256:crypto.createHash('sha256').update(b).digest('hex')};});
const sinkPath=path.join(root,'sources/farmhouse-sink/farmhouse-apron-sink.glb');const sink=fs.readFileSync(sinkPath);if(sink.toString('ascii',0,4)!=='glTF'||sink.readUInt32LE(8)!==sink.length)failures.push('Invalid sink GLB');const gltf=JSON.parse(sink.toString('utf8',20,20+sink.readUInt32LE(12)).trim());
const sinkReport={source:'https://www.innerscene.com/tools/library/3d-parts/apron-sink-farmhouse-sink-d48bb2ce',download:'https://www.innerscene.com/api/library/apron-sink-farmhouse-sink-d48bb2ce/download',license:'CC0, as stated on source listing',sha256:crypto.createHash('sha256').update(sink).digest('hex'),bytes:sink.length,meshes:gltf.meshes?.length||0,materials:gltf.materials?.length||0,animations:gltf.animations?.length||0,externalBuffers:(gltf.buffers||[]).filter(x=>x.uri&&!x.uri.startsWith('data:')).map(x=>x.uri),nativeSource:'GLB only acquired; no native Blender source advertised/verified',inspection:'GLB structure inspected; not rendered or imported into Godot'};
fs.writeFileSync(path.join(root,'sources/farmhouse-sink/provenance.json'),JSON.stringify(sinkReport,null,2));
const report={date:'2026-11-09',indexedAssets:assets.length,localReferences:links,verifiedPackageFiles:ledger.length,blenderSources:inspections.length,blenderMissingImages:inspections.reduce((n,r)=>n+r.missing_images.length,0),godotIgnore:fs.existsSync(path.join(root,'.gdignore')),images,sink:sinkReport,failures};
fs.writeFileSync(path.join(root,'verification.json'),JSON.stringify(report,null,2));
console.log(JSON.stringify({...report,images:images.map(x=>({file:x.file,width:x.width,height:x.height})),sink:sinkReport},null,2));
process.exitCode=failures.length?1:0;
