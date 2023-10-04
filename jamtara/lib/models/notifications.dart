class CustomNotificationModel {
  String type = ''; // agent-added, report-added
  String title = '';
  String body = '';
  String time = '';
  String data = '';
  CustomNotificationModel(
      {this.type = '',
      this.title = '',
      this.body = '',
      this.time = '',
      this.data = ''});
}
