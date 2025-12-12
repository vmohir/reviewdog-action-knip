// Knip Reporter to Output Reviewdog Diagnostic Format (RDFormat)
// https://github.com/reviewdog/reviewdog/tree/master/proto/rdf

const ISSUE_TYPE_CONFIG = {
  files: { message: 'Unused file', severity: 'WARNING' },
  dependencies: { message: 'Unused dependency', severity: 'WARNING' },
  devDependencies: { message: 'Unused devDependency', severity: 'WARNING' },
  optionalPeerDependencies: { message: 'Unused optionalPeerDependency', severity: 'WARNING' },
  unlisted: { message: 'Unlisted dependency', severity: 'ERROR' },
  binaries: { message: 'Unlisted binary', severity: 'ERROR' },
  unresolved: { message: 'Unresolved import', severity: 'ERROR' },
  exports: { message: 'Unused export', severity: 'WARNING' },
  nsExports: { message: 'Unused export in namespace', severity: 'WARNING' },
  types: { message: 'Unused type', severity: 'WARNING' },
  nsTypes: { message: 'Unused type in namespace', severity: 'WARNING' },
  enumMembers: { message: 'Unused enum member', severity: 'WARNING' },
  classMembers: { message: 'Unused class member', severity: 'WARNING' },
  duplicates: { message: 'Duplicate export', severity: 'WARNING' },
};

export default async function reporter({ issues, cwd }) {
  const rdjson = {
    source: {
      name: 'knip',
      url: 'https://knip.dev/'
    },
    diagnostics: []
  };

  // Knip v5+ stores all issues in _files grouped by file path
  const filesWithIssues = issues._files || {};

  for (const [filePath, fileIssues] of Object.entries(filesWithIssues)) {
    for (const issue of fileIssues) {
      const issueType = issue.type;
      const config = ISSUE_TYPE_CONFIG[issueType];

      if (!config) continue;

      const symbol = issue.symbol || '';
      const message = symbol
        ? `${config.message}: ${symbol}`
        : config.message;

      // Convert absolute path to relative path for reviewdog
      let relativePath = filePath;
      if (issue.filePath && cwd && issue.filePath.startsWith(cwd)) {
        relativePath = issue.filePath.slice(cwd.length + 1);
      }

      const diagnostic = {
        message,
        location: {
          path: relativePath,
          range: {
            start: {
              line: issue.line || 1,
              column: (issue.col || 0) + 1
            }
          }
        },
        severity: config.severity,
        code: {
          value: issueType,
          url: `https://knip.dev/reference/issue-types#${issueType.toLowerCase()}`
        }
      };

      rdjson.diagnostics.push(diagnostic);
    }
  }

  console.log(JSON.stringify(rdjson));
}
