# Security Policy

## Supported Versions

We release patches for security vulnerabilities on the most recent release of SciNote. Older releases may not receive fixes.

| Version        | Supported          |
| -------------- | ------------------ |
| Latest release | :white_check_mark: |
| Older releases | :x:                |

## Reporting a Vulnerability

If you believe you have found a security vulnerability in `scinote-web`, please **do not open a public GitHub issue**. Instead, report it privately so we can investigate and release a fix before the details become public.

- **Email:** security@scinote.net
- **What to include:**
  - A description of the vulnerability and its potential impact
  - Steps to reproduce (proof-of-concept code, request/response examples, or screenshots if relevant)
  - The affected version, commit, or deployment (e.g. self-hosted vs. scinote.net)
  - Your contact details for follow-up

You can also use GitHub's [private vulnerability reporting](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/report-privately) feature on this repository, if enabled, as an alternative to email.

## What to Expect

- **Acknowledgment:** within 3 business days of your report.
- **Initial assessment:** within 5 business days, including a severity rating and whether the report is accepted.
- **Updates:** we'll keep you informed of progress until the issue is resolved.
- **Resolution:** timelines depend on severity and complexity, but critical issues are prioritized for immediate remediation.

## Disclosure Policy

We follow a coordinated disclosure approach with a **90-day disclosure deadline**: once a report is confirmed, we ask for up to 90 days to investigate, develop, and release a fix before any public disclosure. This timeline may be shortened if the vulnerability is being actively exploited, or extended by mutual agreement if remediation is more complex than expected. We'll keep reporters informed throughout and coordinate on the timing and content of any public advisory. Once a fix is released, we're happy to credit reporters (with permission) in the release notes or a security advisory.

## Scope

This policy covers the `scinote-eln/scinote-web` codebase and its official deployments. Third-party integrations, dependencies, and plugins not maintained in this repository should be reported to their respective maintainers.

## Questions

For general (non-security) questions about this project, please use the standard GitHub issue tracker instead of the security contact above.
