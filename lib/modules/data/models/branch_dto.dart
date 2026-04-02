import 'package:stock_module/modules/data/models/api_parse.dart';

class BranchDto {
  BranchDto({
    required this.id,
    required this.name,
    this.companyId,
  });

  final String id;
  final String name;
  final String? companyId;

  factory BranchDto.fromJson(Map<String, dynamic> json) {
    final m = asMap(json);
    return BranchDto(
      id: mapString(m, const ['id', 'Id']) ?? '',
      name: mapString(m, const ['name', 'Name']) ?? '',
      companyId: mapString(m, const ['companyId', 'CompanyId']),
    );
  }
}
