class SupportCannedResponseTemplate {
  final String key;
  final String title;
  final String body;

  const SupportCannedResponseTemplate({
    required this.key,
    required this.title,
    required this.body,
  });
}

const List<SupportCannedResponseTemplate> supportCannedResponseTemplates = [
  SupportCannedResponseTemplate(
    key: 'verification_docs_unclear',
    title: 'Verification docs unclear',
    body:
        'Your verification documents are unclear. Please re-upload clear photos of all required documents.',
  ),
  SupportCannedResponseTemplate(
    key: 'please_reupload',
    title: 'Please re-upload',
    body:
        'Please re-upload the requested files. Make sure all details are readable and match your profile.',
  ),
  SupportCannedResponseTemplate(
    key: 'issue_escalated',
    title: 'Issue escalated',
    body:
        'Your issue has been escalated to our operations team. We will update you as soon as we have progress.',
  ),
  SupportCannedResponseTemplate(
    key: 'load_dispute_resolved',
    title: 'Load dispute resolved',
    body:
        'The load dispute has been reviewed and resolved. Please check the latest trip/support updates.',
  ),
];
