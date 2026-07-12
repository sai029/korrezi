#!/usr/bin/env bash
# Flutter Web を Vercel に本番デプロイする。
# 前提: 事前に `vercel login` 済み（初回のみ）。
set -euo pipefail

cd "$(dirname "$0")"

echo "==> flutter build web --release"
flutter build web --release

echo "==> copy vercel.json into build/web (SPAリライト設定)"
cp vercel.json build/web/

echo "==> deploy to Vercel (production, tgz archive で多数ファイルの上限回避)"
cd build/web
npx vercel --prod --archive=tgz

echo "==> done"
