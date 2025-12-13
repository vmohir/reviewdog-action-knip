# GitHub Action: Run knip with reviewdog

This action runs [knip](https://github.com/webpro-nl/knip) with [reviewdog](https://github.com/reviewdog/reviewdog) on pull requests to find unused files, dependencies, and exports.

## Prerequisites

You must have knip installed in your project:

```shell
npm install knip -D
```

## Usage

```yml
name: knip
on: [pull_request]
jobs:
  knip:
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
```

## Inputs

| Input | Description | Default |
|-------|-------------|---------|
| `github_token` | GitHub token | `${{ github.token }}` |
| `reporter` | Reporter type (`github-pr-review`, `github-pr-check`, `github-check`) | `github-pr-review` |
| `level` | Report level (`info`, `warning`, `error`) | `warning` |
| `filter_mode` | Filter mode (`added`, `diff_context`, `file`, `nofilter`) | `added` |
| `fail_level` | Fail level (`none`, `any`, `info`, `warning`, `error`) | `none` |
| `knip_flags` | Additional flags for knip (e.g., `--config knip.json`) | |
| `workdir` | Working directory | `.` |

## License

MIT
