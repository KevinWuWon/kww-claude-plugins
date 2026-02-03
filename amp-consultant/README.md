# amp-consultant

Consult Sourcegraph's Amp CLI for second opinions on code review, architecture analysis, debugging, and technical research.

## Features

- **Command**: `/amp <question>` - Directly ask Amp a question
- **Command**: `/amp-oracle <question>` - Ask the oracle (mystical prompt format)

## Prerequisites

- [Amp CLI](https://ampcode.com/) installed and configured
- Valid API credentials configured in Amp

## Usage

### General Questions

```
/amp What's the best way to handle this error case?
/amp Review the authentication flow in src/auth/
/amp Is there a potential race condition in this code?
```

### Ask the Oracle

```
/amp-oracle What pattern should I use for this feature?
/amp-oracle How should I refactor this module?
```

## How It Works

1. Takes your question or request
2. Executes `amp -x "prompt"` (execute mode)
3. Presents Amp's analysis with recommendations

For questions requiring code context, the command can pipe file contents to amp for analysis.
