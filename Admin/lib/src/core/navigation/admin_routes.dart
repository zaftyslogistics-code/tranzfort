class AdminRoutes {
  AdminRoutes._();

  static const rootPath = '/';
  static const login = 'login';
  static const dashboard = 'dashboard';
  static const verification = 'verification';
  static const verificationDetail = 'verification-detail';
  static const support = 'support';
  static const supportDetail = 'support-detail';
  static const superOps = 'super-ops';
  static const operationalCaseDetail = 'operational-case-detail';
  static const loadManagement = 'load-management';
  static const loadDetail = 'load-detail';
  static const users = 'users';
  static const userDetail = 'user-detail';
  static const adminManagement = 'admin-management';
  static const auditLogs = 'audit-logs';
  static const settings = 'settings';
  static const notifications = 'notifications';

  static const loginPath = '/login';
  static const dashboardPath = '/dashboard';
  static const verificationPath = '/verification';
  static const verificationDetailPath = '/verification/:caseId';
  static const supportPath = '/support';
  static const supportDetailPath = '/support/:ticketId';
  static const superOpsPath = '/super-ops';
  static const operationalCaseDetailPath = '/super-ops/:caseId';
  static const loadManagementPath = '/loads';
  static const loadDetailPath = '/loads/:loadId';
  static const usersPath = '/users';
  static const userDetailPath = '/users/:userId';
  static const adminManagementPath = '/admin-management';
  static const auditLogsPath = '/audit-logs';
  static const settingsPath = '/settings';
  static const notificationsPath = '/notifications';

  static String verificationDetailPathFor(String caseId) => '/verification/$caseId';
  static String supportDetailPathFor(String ticketId) => '/support/$ticketId';
  static String operationalCaseDetailPathFor(String caseId) => '/super-ops/$caseId';
  static String loadDetailPathFor(String loadId) => '/loads/$loadId';
  static String userDetailPathFor(String userId) => '/users/$userId';
}
