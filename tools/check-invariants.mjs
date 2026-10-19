#!/usr/bin/env node
/**
 * 静态不变量检查 —— 防止「改了一个、坏了另一个」。
 *
 * 覆盖两类本项目踩过的坑：
 *
 *   1. ForEach 的 key 不含数据
 *      只写 `\`dot_${city.id}\`` 这类，数据变了 key 不变，ArkUI 会复用旧子组件，
 *      表现为「数据明明刷新了，界面不更新」。曾导致卡片和下拉刷新双双失效。
 *
 *   2. 卡片 @LocalStorageProp 字段与 WxWidgetBinding 对不上
 *      字段名打错或漏传时，卡片静默显示旧数据，没有编译错误。
 *
 * 用法：node tools/check-invariants.mjs
 * 退出码：0 通过，1 发现违规
 */

import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join, relative } from 'node:path';

const ROOT = new URL('..', import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1');
const SRC = join(ROOT, 'entry/src/main/ets');

/** 视为「数据字段」的名字：key 里出现任意一个，说明会随数据变化 */
const DATA_FIELD = /\b(temp|min|max|code|pop|value|sub|label|rangeText|desc|isDay|isPast|aqiText|feelsLike|humidity|theme|gradient)\b/;

/** 允许不含数据字段的例外，形如 `// check-invariants: skip=纯静态列表` */
const SKIP_MARK = /check-invariants:\s*skip/;

const problems = [];

function walk(dir) {
  const out = [];
  for (const name of readdirSync(dir)) {
    const full = join(dir, name);
    if (statSync(full).isDirectory()) {
      out.push(...walk(full));
    } else if (name.endsWith('.ets')) {
      out.push(full);
    }
  }
  return out;
}

/** 从 `ForEach(` 开始，找到配对的 keyGenerator（`}, (x: T) => ...)`） */
function checkForEach(file, lines) {
  for (let i = 0; i < lines.length; i++) {
    if (!lines[i].includes('ForEach(')) {
      continue;
    }
    // 往上找 3 行，看看有没有 skip 标记
    const context = lines.slice(Math.max(0, i - 3), i + 1).join('\n');
    if (SKIP_MARK.test(context)) {
      continue;
    }

    // 往下扫，找 keyGenerator：以 `}, (` 开头且含 `=>`
    let keyLine = -1;
    let keyExpr = '';
    for (let j = i + 1; j < Math.min(lines.length, i + 200); j++) {
      const line = lines[j];
      if (/^\s*\}, \(/.test(line) && line.includes('=>')) {
        keyLine = j;
        keyExpr = line.slice(line.indexOf('=>') + 2).trim().replace(/\)\s*$/, '');
        break;
      }
      // 遇到同一缩进级别的闭合括号，说明这个 ForEach 没有 keyGenerator
      if (/^\s{0,8}\}\)/.test(line)) {
        break;
      }
    }

    if (keyLine < 0) {
      problems.push({
        file, line: i + 1,
        msg: 'ForEach 缺少 keyGenerator（第三个参数）'
      });
      continue;
    }
    if (!DATA_FIELD.test(keyExpr)) {
      problems.push({
        file, line: keyLine + 1,
        msg: `ForEach 的 key 不含数据字段，数据变化时不会重绘：${keyExpr}`
      });
    }
  }
}

/** 卡片声明的 @LocalStorageProp 必须在 WxWidgetBinding 里有对应字段 */
function checkWidgetFields(bindingFile, cardFiles) {
  const bindingSrc = readFileSync(bindingFile, 'utf8');
  const iface = bindingSrc.match(/export interface WxWidgetBinding \{([\s\S]*?)\n\}/);
  if (!iface) {
    problems.push({ file: bindingFile, line: 1, msg: '找不到 WxWidgetBinding 接口定义' });
    return;
  }
  const declared = new Set();
  for (const m of iface[1].matchAll(/^\s{2}(\w+)\s*:/gm)) {
    declared.add(m[1]);
  }

  for (const cardFile of cardFiles) {
    const src = readFileSync(cardFile, 'utf8');
    for (const m of src.matchAll(/@LocalStorageProp\('(\w+)'\)/g)) {
      const key = m[1];
      if (!declared.has(key)) {
        const line = src.slice(0, m.index).split('\n').length;
        problems.push({
          file: cardFile, line,
          msg: `卡片读取 '${key}'，但 WxWidgetBinding 里没有这个字段（会静默显示旧数据）`
        });
      }
    }
  }
}

const files = walk(SRC);

for (const file of files) {
  const lines = readFileSync(file, 'utf8').split('\n');
  checkForEach(file, lines);
}

checkWidgetFields(
  join(SRC, 'service/WidgetBinding.ets'),
  [join(SRC, 'widget/pages/WidgetCard.ets'), join(SRC, 'widget/pages/WidgetCardDays.ets')]
);

if (problems.length === 0) {
  console.log(`✓ 检查通过：${files.length} 个 .ets 文件，未发现违规`);
  process.exit(0);
}

console.error(`✗ 发现 ${problems.length} 处违规：\n`);
for (const p of problems) {
  console.error(`  ${relative(ROOT, p.file)}:${p.line}`);
  console.error(`    ${p.msg}\n`);
}
process.exit(1);
