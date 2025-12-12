// Knip Reporter to Output Reviewdog Diagnostic Format (RDFormat)
// https://github.com/reviewdog/reviewdog/tree/master/proto/rdf

const ISSUE_TYPES = {
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

const getRelativePath = (filePath, absolutePath, cwd) =>
  absolutePath?.startsWith(cwd) ? absolutePath.slice(cwd.length + 1) : filePath;

const createDiagnostic = ({ message, path, line = 1, col = 0, issueType }) => ({
  message,
  location: {
    path,
    range: {
      start: { line, column: col + 1 }
    }
  },
  severity: ISSUE_TYPES[issueType]?.severity ?? 'WARNING',
  code: {
    value: issueType,
    url: `https://knip.dev/reference/issue-types#${issueType.toLowerCase()}`
  }
});

const formatMessage = (baseMessage, symbol) =>
  symbol ? `${baseMessage}: ${symbol}` : baseMessage;

export default async function reporter({ issues, cwd }) {
  const diagnostics = [];

  // Process _files (knip v5+ consolidated view)
  const filesIssues = Object.entries(issues._files ?? {}).flatMap(([filePath, fileIssues]) =>
    fileIssues
      .filter(issue => ISSUE_TYPES[issue.type])
      .map(issue => createDiagnostic({
        message: formatMessage(ISSUE_TYPES[issue.type].message, issue.symbol),
        path: getRelativePath(filePath, issue.filePath, cwd),
        line: issue.line,
        col: issue.col,
        issueType: issue.type
      }))
  );

  // Process individual issue type objects
  // Structure: issues[type][filePath][symbolName] = [{ line, col, pos }]
  const typeIssues = Object.entries(ISSUE_TYPES).flatMap(([issueType, config]) =>
    Object.entries(issues[issueType] ?? {}).flatMap(([filePath, symbols]) =>
      Object.entries(symbols ?? {}).flatMap(([symbolName, locations]) =>
        [locations].flat().filter(Boolean).map(loc => createDiagnostic({
          message: formatMessage(config.message, symbolName),
          path: filePath,
          line: loc?.line,
          col: loc?.col,
          issueType
        }))
      )
    )
  );

  diagnostics.push(...filesIssues, ...typeIssues);

  const rdjson = {
    source: { name: 'knip', url: 'https://knip.dev/' },
    diagnostics
  };

  console.log(JSON.stringify(rdjson));
}
