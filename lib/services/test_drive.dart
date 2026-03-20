import 'package:googleapis/drive/v3.dart' as drive;

void main() {
  drive.DriveApi? api;
  api!.files.list($fields: "id");
}
