# /workspace/code/mmsegmentation/tools/bench_infer_city.py
import argparse, glob, time, os
import torch, mmcv
from mmengine.config import Config
from mmseg.apis import init_model, inference_model

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('config')
    ap.add_argument('ckpt')
    ap.add_argument('--pattern', default='data/cityscapes/leftImg8bit/val/*/*.png')
    ap.add_argument('--warmup', type=int, default=20)
    ap.add_argument('--limit', type=int, default=500)  # Cityscapes val=500
    args = ap.parse_args()

    cfg = Config.fromfile(args.config)
    model = init_model(cfg, args.ckpt, device='cuda:0')
    paths = sorted(glob.glob(args.pattern))[:args.limit]
    assert paths, f'No images found at {args.pattern}'

    # warmup
    for p in paths[:args.warmup]:
        inference_model(model, p)

    torch.cuda.synchronize()
    t0 = time.perf_counter()
    for p in paths:
        inference_model(model, p)
    torch.cuda.synchronize()
    t1 = time.perf_counter()

    n = len(paths)
    total_ms = (t1 - t0) * 1000.0
    ms_per_img = total_ms / n
    fps = 1000.0 / ms_per_img
    print(f'Images: {n}  Total: {total_ms:.2f} ms  Latency: {ms_per_img:.2f} ms/img  FPS: {fps:.2f}')

if __name__ == '__main__':
    main()

