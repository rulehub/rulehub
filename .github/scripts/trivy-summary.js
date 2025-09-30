#!/usr/bin/env node
/* eslint-disable no-console */
const fs = require('fs');

function summarizeSarif(path) {
  let total = 0,
    high = 0,
    med = 0,
    low = 0;
  try {
    const txt = fs.readFileSync(path, 'utf8');
    if (txt && txt.trim().length > 0) {
      const sar = JSON.parse(txt);
      const results = (sar.runs || []).flatMap((r) => r.results || []);
      total = results.length;
      for (const r of results) {
        if (r.level === 'error') high++;
        else if (r.level === 'warning') med++;
        else if (r.level === 'note') low++;
      }
    }
  } catch (_) {
    // ignore
  }
  return { total, high, med, low };
}

const sarifPath = process.argv[2] || 'trivy-results.sarif';
const { total, high, med, low } = summarizeSarif(sarifPath);
const body = [
  '### Trivy IaC scan summary',
  `- Findings: ${total} (high: ${high}, medium: ${med}, low: ${low})`,
  "- Full details are in the Security > Code scanning alerts tab under tool 'Trivy'.",
].join('\n');
console.log(body);
