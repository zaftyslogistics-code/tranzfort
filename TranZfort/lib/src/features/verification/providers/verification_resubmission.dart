/// Whether the profile verification state should open the wizard in resubmit mode.
bool isVerificationResubmission(String verificationStatus) {
  return verificationStatus.trim().toLowerCase() == 'rejected';
}
