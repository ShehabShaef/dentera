/// Academic dental catalog defining standardized departments, procedures,
/// and departmental theme colors based on clinical guidelines.
class DentalCatalog {
  DentalCatalog._();

  /// The fallback / custom extension option.
  static const String otherOption = 'Other...';

  // 10 Standard Academic Dental Departments
  static const String oralSurgery = 'Oral Surgery';
  static const String oralMedicine = 'Oral Medicine';
  static const String removableProsthodontics = 'Removable Prosthodontics';
  static const String fixedProsthodontics = 'Fixed Prosthodontics';
  static const String prosthodontics = 'Prosthodontics';
  static const String operative = 'Operative';
  static const String endodontics = 'Endodontics';
  static const String orthodontics = 'Orthodontics';
  static const String pedodontics = 'Pedodontics';
  static const String periodontics = 'Periodontics';

  /// Standard academic departments list in canonical order.
  static const List<String> standardDepartments = <String>[
    oralSurgery,
    oralMedicine,
    removableProsthodontics,
    fixedProsthodontics,
    prosthodontics,
    operative,
    endodontics,
    orthodontics,
    pedodontics,
    periodontics,
  ];

  /// Standard departments plus the "Other..." custom option.
  static List<String> get departmentOptions => <String>[
        ...standardDepartments,
        otherOption,
      ];

  /// Predefined procedural catalogs for each standard academic department.
  static const Map<String, List<String>> proceduralCatalogs = <String, List<String>>{
    oralSurgery: <String>[
      'Simple Extraction',
      'Surgical Extraction',
      'Impacted Third Molar Extraction',
      'Alveoloplasty',
      'Suture Removal',
      'Diagnostic Biopsy',
    ],
    oralMedicine: <String>[
      'Comprehensive Oral Examination',
      'Diagnostic Biopsy',
      'Oral Mucosal Lesion Management',
      'TMJ Evaluation',
      'Salivary Gland Assessment',
    ],
    removableProsthodontics: <String>[
      'Complete Denture',
      'Removable Partial Denture',
      'Single Complete Denture',
      'Immediate Denture',
      'Reline / Rebase',
      'RPI Clasp Assembly',
    ],
    fixedProsthodontics: <String>[
      'Single Crown Preparation',
      'Fixed Partial Denture (Bridge)',
      'Post and Core',
      'Porcelain Laminate Veneer',
      'Provisional Restoration',
    ],
    prosthodontics: <String>[
      'Complete Denture',
      'Removable Partial Denture',
      'Single Complete Denture',
      'RPI Clasp Assembly',
      'Crown & Bridge',
    ],
    operative: <String>[
      'Class I Composite',
      'Class II Composite',
      'Class II Amalgam',
      'Class III Composite',
      'Class IV Composite',
      'Class V Restoration',
      'Complex Amalgam / Core',
    ],
    endodontics: <String>[
      'Anterior Root Canal Treatment',
      'Premolar Root Canal Treatment',
      'Molar Root Canal Treatment',
      'Emergency Pulpectomy',
      'Root Canal Retreatment',
    ],
    orthodontics: <String>[
      'Cephalometric & Cast Analysis',
      'Removable Appliance Insertion',
      'Fixed Bracket Bonding',
      'Space Maintainer',
      'Orthodontic Wire Adjustment',
    ],
    pedodontics: <String>[
      'Primary Pulpotomy',
      'Stainless Steel Crown',
      'Space Maintainer',
      'Pit and Fissure Sealant',
      'Topical Fluoride Application',
      'Pediatric Simple Extraction',
    ],
    periodontics: <String>[
      'Scaling & Root Planing',
      'Gingivectomy',
      'Crown Lengthening',
      'Periodontal Flap Surgery',
      'Subgingival Debridement',
    ],
  };

  /// Department theme colors for consistent visual hierarchy.
  static const Map<String, String> departmentColors = <String, String>{
    oralSurgery: '#2E3F50',
    oralMedicine: '#455A64',
    removableProsthodontics: '#003E6F',
    fixedProsthodontics: '#1E568C',
    prosthodontics: '#003E6F',
    operative: '#006A64',
    endodontics: '#1E568C',
    orthodontics: '#7B1FA2',
    pedodontics: '#C2185B',
    periodontics: '#37485A',
  };

  /// Normalizes department name and matches against standard departments or common clinical aliases.
  static String? canonicalDepartment(String? department) {
    if (department == null) return null;
    final trimmed = department.trim().toLowerCase();
    for (final dept in standardDepartments) {
      if (dept.toLowerCase() == trimmed) return dept;
    }
    // Handle recognized clinical aliases
    if (trimmed == 'operative dentistry') return operative;
    if (trimmed == 'pediatric dentistry' || trimmed == 'pediatric') return pedodontics;
    return null;
  }

  /// Checks whether a given department name is part of the standardized dental catalog.
  static bool isStandardDepartment(String? department) =>
      canonicalDepartment(department) != null;

  /// Returns the standard procedures associated with a department.
  static List<String> getProceduresForDepartment(String department) {
    final canonical = canonicalDepartment(department);
    if (canonical == null) return const <String>[];
    return proceduralCatalogs[canonical] ?? const <String>[];
  }

  /// Returns the procedural options for a standard department, appending the "Other..." option.
  static List<String> getProcedureOptionsForDepartment(String department) {
    final procedures = getProceduresForDepartment(department);
    return <String>[
      ...procedures,
      otherOption,
    ];
  }

  /// Returns the default theme color hex for a given department.
  static String getDefaultColorForDepartment(String department) {
    final canonical = canonicalDepartment(department);
    return departmentColors[canonical] ?? '#003E6F';
  }
}
