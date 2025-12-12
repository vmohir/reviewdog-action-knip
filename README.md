# GitHub Action: Run knip with reviewdog

This action runs [knip](https://github.com/webpro-nl/knip) with
[reviewdog](https://github.com/reviewdog/reviewdog) on pull requests to find
unused files, dependencies, and exports.

## Inputs

### `github_token`

**Required**. Default is `${{ github.token }}`.

### `level`

Optional. Report level for reviewdog \[`info`,`warning`,`error`\].
It's same as `-level` flag of reviewdog. Default is `warning`.

### `reporter`

Reporter of reviewdog command \[`github-pr-check`,`github-check`,`github-pr-review`\].
Default is `github-pr-review`.
It's same as `-reporter` flag of reviewdog.

`github-pr-review` can use Markdown and add a link to rule page in reviewdog reports.

### `tool_name`

Optional. Tool name to use for reviewdog reporter. Default is `knip`.

### `filter_mode`

Optional. Filtering mode for the reviewdog command \[`added`,`diff_context`,`file`,`nofilter`\].
Default is `added`.

### `fail_level`

Optional. If set to `none`, always use exit code 0 for reviewdog. Otherwise, exit code 1 for reviewdog if it finds at least 1 issue with severity greater than or equal to the given level.
Possible values: [`none`, `any`, `info`, `warning`, `error`]
Default is `none`.

### `fail_on_error`

Deprecated, use `fail_level` instead.
Optional. Exit code for reviewdog when errors are found \[`true`,`false`\]
Default is `false`.

### `reviewdog_flags`

Optional. Additional reviewdog flags.

### `knip_flags`

Optional. Flags and args for knip command.
Examples:
- `--config custom-knip.json` - Use custom config file
- `--workspace packages/foo` - Run in specific workspace
- `--include files,exports` - Only check specific issue types

### `workdir`

Optional. The directory from which to look for and run knip. Default '.'.

## Prerequisites

You **must** have [knip](https://github.com/webpro-nl/knip) installed in your project's `package.json`:

```shell
npm install knip -D
```

You can create a [knip config](https://knip.dev/overview/configuration) and this action uses that config too.

## Example usage

### Basic Usage

```yml
name: reviewdog
on: [pull_request]
jobs:
  knip:
    name: runner / knip
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: write
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - run: npm install
      - uses: reviewdog/action-knip@v1
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          reporter: github-pr-review
```

### With Custom Config

```yml
name: reviewdog
on: [pull_request]
jobs:
  knip:
    name: runner / knip
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - run: npm install
      - uses: reviewdog/action-knip@v1
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          reporter: github-pr-review
          knip_flags: '--config knip.json'
```

### Monorepo Usage

```yml
name: reviewdog
on: [pull_request]
jobs:
  knip:
    name: runner / knip
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - run: npm install
      - uses: reviewdog/action-knip@v1
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          reporter: github-pr-review
          knip_flags: '--workspace packages/my-package'
```

### Fail on Issues

```yml
name: reviewdog
on: [pull_request]
jobs:
  knip:
    name: runner / knip
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - run: npm install
      - uses: reviewdog/action-knip@v1
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          reporter: github-pr-review
          fail_level: warning
```

## Issue Types Detected

Knip detects the following types of issues:

| Issue Type | Severity | Description |
|------------|----------|-------------|
| `files` | WARNING | Unused files |
| `dependencies` | WARNING | Unused dependencies |
| `devDependencies` | WARNING | Unused dev dependencies |
| `exports` | WARNING | Unused exports |
| `types` | WARNING | Unused type exports |
| `classMembers` | WARNING | Unused class members |
| `enumMembers` | WARNING | Unused enum members |
| `duplicates` | WARNING | Duplicate exports |
| `unlisted` | ERROR | Unlisted dependencies |
| `unresolved` | ERROR | Unresolved imports |
| `binaries` | ERROR | Unlisted binaries |

## License

MIT
