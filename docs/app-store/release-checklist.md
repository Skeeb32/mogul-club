# App Store release blockers

This is a development demo, not a submission-ready financial service. Before submission verify current Apple guidance and obtain qualified legal review.

- Working Xcode build, simulator UI tests, accessibility and physical device testing.
- Legal entity, bundle ID, signing, developer membership and financial-services authorization.
- Approved offering and intermediary model, funds flow and investor restrictions.
- Configure and exercise real Firebase authentication, provider callbacks, session revocation, account deletion, and documented retention.
- Published privacy policy, terms and support contact (none invented).
- Accurate App Privacy, permissions, SDK review, screenshots, metadata and reviewer instructions.
- App icon, production backend availability, TestFlight verification and release approval.

Official sources to review at release:
- https://developer.apple.com/app-store/review/guidelines/
- https://developer.apple.com/support/offering-account-deletion-in-your-app/
- https://www.sec.gov/resources-small-businesses/exempt-offerings/regulation-crowdfunding
- https://www.investor.gov/

Apple approval is not regulatory approval. This checklist does not establish legal compliance.

Source review on 2026-10-24: checked Apple's current App Review Guidelines and account-deletion guidance. Recheck at submission. The account-deletion guidance now resolves to https://developer.apple.com/help/app-review/guideline-reference/5-1-1-account-deletion . It calls for in-app deletion initiation when account creation is supported, with legally required retention handled explicitly. A Firebase account workflow is implemented behind unconfigured provider credentials in the native demo. Configure approved project credentials, test provider flows and deletion, and establish approved account data-retention behavior before release.
