import '../constants/dental_catalog.dart';

/// Contract for accessing the academic dental taxonomy catalog.
abstract class DentalCatalogRepository {
  /// Returns the canonical list of standard academic departments.
  List<String> getStandardDepartments();

  /// Returns the list of department options including the "Other..." extension.
  List<String> getDepartmentOptions();

  /// Returns standard procedures for a given department.
  List<String> getProceduresForDepartment(String department);

  /// Returns procedure options for a given department including "Other...".
  List<String> getProcedureOptionsForDepartment(String department);

  /// Checks if a department name matches a standard catalog department.
  bool isStandardDepartment(String? department);

  /// Returns the recommended theme color for a department.
  String getDefaultColor(String department);
}

/// In-memory reference implementation backed by [DentalCatalog].
class DefaultDentalCatalogRepository implements DentalCatalogRepository {
  const DefaultDentalCatalogRepository();

  @override
  List<String> getStandardDepartments() => DentalCatalog.standardDepartments;

  @override
  List<String> getDepartmentOptions() => DentalCatalog.departmentOptions;

  @override
  List<String> getProceduresForDepartment(String department) =>
      DentalCatalog.getProceduresForDepartment(department);

  @override
  List<String> getProcedureOptionsForDepartment(String department) =>
      DentalCatalog.getProcedureOptionsForDepartment(department);

  @override
  bool isStandardDepartment(String? department) =>
      DentalCatalog.isStandardDepartment(department);

  @override
  String getDefaultColor(String department) =>
      DentalCatalog.getDefaultColorForDepartment(department);
}
