class DivisionModel {
  String code = '';
  String createdOn = '';
  String createdBy = '';
  String id = '';
  DivisionModel(
      {this.code = '',
      this.createdOn = '',
      this.createdBy = '',
      this.id = ''}) {}
}

class DivisionSelectionModel {
  DivisionModel division;
  bool isSelected;
  DivisionSelectionModel({
    required this.division,
    required this.isSelected,
  });
}
