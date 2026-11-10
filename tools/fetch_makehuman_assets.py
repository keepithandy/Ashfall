"""Fetch selected CC0 core assets using verified ZIP byte ranges, not the 268 MB pack.
No source from the archive is executed. Kept as a reproducible asset-fetch recipe.
"""
import argparse
import binascii
import os
import struct
import urllib.request
import zlib
from concurrent.futures import ThreadPoolExecutor

URL = 'https://files.makehumancommunity.org/asset_packs/makehuman_system_assets/makehuman_system_assets_cc0.zip'
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'assets', 'characters', 'scavenger', 'source', 'makehuman')


def get_range(start, end):
    request = urllib.request.Request(URL, headers={'Range': f'bytes={start}-{end}', 'User-Agent': 'Ashfall-asset-import/1.0'})
    with urllib.request.urlopen(request, timeout=45) as response:
        assert response.status == 206, 'Server must honor byte ranges'
        data = response.read(end-start+2)
        assert len(data) == end-start+1, 'Unexpected byte range length'
        return data


def directory():
    request = urllib.request.Request(URL, method='HEAD')
    with urllib.request.urlopen(request, timeout=30) as response:
        length = int(response.headers['Content-Length'])
    tail = get_range(length-65557, length-1)
    end = tail.rfind(b'PK\x05\x06')
    record = struct.unpack_from('<4s4H2LH', tail, end)
    size, offset = record[5:7]
    data = get_range(offset, offset+size-1)
    entries = []
    pos = 0
    while pos < len(data):
        record = struct.unpack_from('<4s6H3L5H2L', data, pos)
        assert record[0] == b'PK\x01\x02'
        method, crc, compressed, uncompressed = record[4], record[7], record[8], record[9]
        name_len, extra_len, comment_len = record[10:13]
        name = data[pos+46:pos+46+name_len].decode('utf-8')
        entries.append((name, method, crc, compressed, uncompressed, record[-1]))
        pos += 46+name_len+extra_len+comment_len
    return entries


def extract(entry):
    name, method, crc, size, unpacked, offset = entry
    relative = name.replace('\\', '/').strip('/')
    assert '..' not in relative.split('/') and ':' not in relative
    header = get_range(offset, offset+29)
    assert header[:4] == b'PK\x03\x04'
    name_len, extra_len = struct.unpack_from('<HH', header, 26)
    start = offset+30+name_len+extra_len
    ranges=[(i,min(i+131071,start+size-1)) for i in range(start,start+size,131072)]
    with ThreadPoolExecutor(max_workers=8) as pool:
        compressed=b''.join(pool.map(lambda r:get_range(*r),ranges))
    content = zlib.decompress(compressed, -15) if method == 8 else compressed
    assert len(content) == unpacked and binascii.crc32(content) & 0xffffffff == crc
    path = os.path.abspath(os.path.join(OUT, *relative.split('/')))
    assert os.path.commonpath([path, OUT]) == OUT
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'wb') as handle:
        handle.write(content)
    print('EXTRACTED', name, len(content), flush=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--fetch', action='store_true')
    args = parser.parse_args()
    for entry in directory():
        name = entry[0]
        if name.startswith(('skins/middleage_caucasian_male/', 'hair/short02/', 'eyes/low-poly/')) or name in ['eyes/materials/brown_eye.png','eyes/materials/brown.mhmat']:
            print(name, entry[4], flush=True)
            if args.fetch and entry[4] > 0:
                extract(entry)
