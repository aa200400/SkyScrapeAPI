library sky_types;

/// [Term] allow for the scrapers to sort through the grades and retrieve grades for certain terms.
///
/// [Term] is JSON compatible and can be converted to a JSON if needed.
class Term {
  /// TermCode is the identifier used to identify the term.
  String termCode;

  /// TermName is the name of the term used if needed for extra identification or display
  String termName;

  // Simple constructor to initialize the termCode and termName
  Term(this.termCode, this.termName);

  @override
  String toString() {
    return "$termCode : $termName";
  }

  Term.fromJson(Map<String, dynamic> json)
      : termCode = json['termCode'],
        termName = json['termName'];

  Map<String, dynamic> toJson() => {
        'termCode': termCode,
        'termName': termName,
      };

  /// Compares the term codes only
  @override
  bool operator ==(other) {
    if (other is Term) {
      return (other).termCode == this.termCode;
    } else {
      return false;
    }
  }

  @override
  int get hashCode => termCode.hashCode;
}

/// [GridBox] is a root type that has many children. These children correspond to the boxes in your grade book.
///
/// [GridBox] only has 3 children
/// * [TeacherIDBox]
/// * [GradeTextBox] has more children that allow actual grades to be distinguished from teacher information or course information
/// * [AssignmentsGridBox]
class GridBox {
  /// Does the [GridBox] lead to another page? Usually only [GradeBox] will have a true [clickable] attribute.
  bool clickable = false;
}

/// AssignmentListSmaller is mainly used for servers who want quick and precise loading of assignments.
/// This data type stores assignments in the grade book, so it can easily be accessed with one post statement.
class AssignmentsListSmaller extends GridBox {
  List<Assignment> assignments = [];

  AssignmentsListSmaller() {
    super.clickable = true;
  }

  @override
  String toString() {
    return 'AssignmentsListSmaller{assignments: $assignments}';
  }
}

/// [TeacherIDBox] tells you course and teacher information.
///
/// [TeacherIDBox] gives only gives you information about a specific course and is usually the first in a [GridBox] List.
/// [TeacherIDBox] **USUALLY** marks the beginning of a new course. If you are using the API, you can make a for loop like the following
///
/// ```dart
/// for (GridBox x in list){
///   if (x is TeacherIDBox) <init code>
///   else <check for the other types>
/// }
/// ```
/// You can also use a switch case statement.
///
/// ```dart
/// for (GridBox x in list){
///   switch (x.runtimeType) {
///   case TeacherIDBox:
///      <init code>
///      break;
///   <more cases>
///   default:
///     <default case, most likely an error>
///   }
/// }
/// ```
class TeacherIDBox extends GridBox {
  String teacherName;
  String timePeriod;
  String courseName;

  TeacherIDBox(this.teacherName, this.courseName, this.timePeriod);

  @override
  String toString() {
    return teacherName + ":" + courseName + ":" + timePeriod;
  }
}

/// [GradeTextBox] is a root that helps distinguish the difference between grades and teacher information
///
/// There are only two children of [GradeTextBox]
/// * [LessInfoBox]
/// * [GradeBox]
class GradeTextBox extends GridBox {
  Term term;

  GradeTextBox(this.term);
}

/// [LessInfoBox] is an unclickable behavior or letter grade.
class LessInfoBox extends GradeTextBox {
  String behavior;

  /// Identification for which term [LessInfoBox] is in.
  LessInfoBox(this.behavior, Term term) : super(term);

  @override
  String toString() {
    return term.toString() + ":" + behavior;
  }
}

/// [GradeBox] is most likely a clickable numbered grade part of a specific term
class GradeBox extends GradeTextBox {
  String courseNumber;
  String grade;
  String studentID;

  /// Identification for which term [GradeBox] is in.
  GradeBox(this.courseNumber, Term term, this.grade, this.studentID)
      : super(term);

  //For debugging only.
  @override
  String toString() {
    return "${this.term.toString()} for ${this.grade} for course # ${this.courseNumber} for student ${this.studentID}";
  }
}

/// [AssignmentsGridBox] is the parent of multiple child types that allow for more categorization
class AssignmentsGridBox extends GridBox {
  /// All the attributes like grades, post values, and more.
  /// **NOTE: THIS MAP IS NOT SAFE TO MODIFY IN YOUR CODE. DO IT WITH CAUTION**
  Map<String, String> attributes;

  AssignmentsGridBox(this.attributes);

  @override
  String toString() {
    return "";
  }

  /// Attempts to get the assignment name
  String getAssignment() {
    return attributes[attributes.keys.toList()[1]];
  }

  /// Attempts to get a decimal grade if there is one.
  /// If there is no decimal grade in the map, then it'll attempt to find and return the integer grade by calling [getIntGrade()]
  /// Read [getIntGrade()] documentation to see what it returns.
  String getDecimal() {
    for (String a in attributes.values) {
      if (double.tryParse(a) != null && a.contains('.')) {
        return a;
      }
    }
    return getIntGrade();
  }

  /// Attempts to find an integer grade in the map.
  /// If one is not found, it'll return null.
  /// **NOTE: REMEMBER TO CHECK FOR THIS NULL IN YOUR CODE**
  String getIntGrade() {
    for (String val in attributes.values) {
      if (int.tryParse(val) != null) {
        return val;
      }
    }
    return null;
  }
}

/// [Assignment] is an assignment scraped from the API
///
/// [Assignment] is really hard to make, so custom declarations of Assignments is highly discouraged.
class Assignment extends AssignmentsGridBox {
  /// Post required attribute. Do not worry about this value if you do not plan to modify [Assignment]
  String studentID;

  /// Post required attribute. Do not worry about this value if you do not plan to modify [Assignment]
  String assignmentID;

  /// Post required attribute. Do not worry about this value if you do not plan to modify [Assignment]
  String gbID;
  String assignmentName;

  Assignment(this.studentID, this.assignmentID, this.gbID, this.assignmentName,
      Map<String, String> attributes)
      : super(attributes);

  @override
  String toString() {
    return 'Assignment{studentID: $studentID, assignmentID: $assignmentID,gbID: $gbID, assignmentName: $assignmentName, attributes: $attributes}';
  }
}

/// [CategoryHeader] is an category scraped from the API
///
/// [CategoryHeader] marks the beginning of a new Category, so it contains weight information and juicy stuff that allows you to distinguish assignments from categories
class CategoryHeader extends AssignmentsGridBox {
  String catName;
  String weight;

  CategoryHeader(this.catName, this.weight, Map<String, String> attributes)
      : super(attributes);

  @override
  String toString() {
    return 'CategoryHeader{catName: $catName,weight: $weight}';
  }
}

/// [AssignmentInfoBox] contains the attribute name and the value that the attribute holds
/// [infoName] and [info] are both paired together to declare a specific value. For example, "Due Date" and "9/3/19"
class AssignmentInfoBox {
  String infoName;
  String info;

  /// UI Message for apps. It essentially combines the [infoName] and [info].
  String getUIMessage() {
    return infoName + ' ' + (info != null ? info : "");
  }

  AssignmentInfoBox(this.infoName, this.info);

  @override
  String toString() {
    return 'AssignmentInfoBox{infoName: $infoName, info: $info}';
  }
}

/// [SkywardSearchState] is a US State, except for "International" that has an ID to input into the District Searcher
class SkywardSearchState {
  String stateName;
  String stateID;

  SkywardSearchState(this.stateName, this.stateID);

  @override
  String toString() {
    return 'State{stateName: $stateName, stateID: $stateID}';
  }
}

/// [SkywardDistrict] are usually returned a list and contains results taken from searching for districts.
///
/// [SkywardDistrict] is JSON compatible and can be used to store SkywardDistricts or use it in a server to return as a json file.
class SkywardDistrict {
  String districtName;
  String districtLink;

  SkywardDistrict(this.districtName, this.districtLink);

  SkywardDistrict.fromJson(Map<String, dynamic> json)
      : districtName = json['districtName'],
        districtLink = json['districtLink'];

  Map<String, dynamic> toJson() => {
        'districtName': districtName,
        'districtLink': districtLink,
      };

  @override
  bool operator ==(other) {
    if (other is SkywardDistrict)
      return districtLink == other.districtLink;
    else
      return false;
  }

  @override
  int get hashCode => districtLink.hashCode;

  @override
  String toString() {
    return 'SkywardDistrict{districtName: $districtName, districtLink: $districtLink}';
  }
}

/// [SchoolYear] is usually returned in a List from [SkywardAPICore.getHistory()]
///
/// SchoolYear provides information about the school year and is JSON Compatible so it can be saved or returned from a server
/// The [description] of the [SchoolYear] is just the name of the [SchoolYear] under Skyward. [terms] are also taken just in case your district has changed terms in its skyward history.
/// [classes] is a list of [Class], for more information, read up on [Class] documentation.
class SchoolYear {
  String description;
  List<Term> terms;
  //First String represents class, in each class theres a map of the term and then the grade of that term.
  List<Class> classes;

  /// This is an extra attribute you can use in your application just in case you need it.
  bool isEnabled = true;

  SchoolYear();

  SchoolYear.fromJson(Map<String, dynamic> json)
      : description = json['description'],
        terms = getTermsFromEncodedTermsList(json['terms']),
        classes = getClassesFromEncodedClassesList(json['classes']),
        isEnabled = json['isEnabled'];

  /// Function to convert encoded terms to a list of terms. Be careful while using this because this should only be used by the API and not the user. Unless the user is trying to make a custom JSON Manager.
  static List<Term> getTermsFromEncodedTermsList(List terms) {
    List<Term> fin = [];
    for (var x in terms) {
      fin.add(Term.fromJson(x));
    }
    return fin;
  }

  /// Classes retrieved. **MAY CAUSE ERRORS IF YOU ATTEMPT TO USE THIS FUNCTION**
  static List<Class> getClassesFromEncodedClassesList(List classes) {
    List<Class> fin = [];
    for (var x in classes) {
      fin.add(Class.fromJson(x));
    }
    return fin;
  }

  Map<String, dynamic> toJson() => {
        'description': description,
        'terms': terms,
        'classes': classes,
        'isEnabled': isEnabled
      };

  @override
  String toString() {
    return 'SchoolYear{description: $description, classes: $classes}';
  }

  @override
  bool operator ==(other) {
    return classes.length == other.classes.length;
  }

  @override
  int get hashCode => description.hashCode;
}

/// [Class] is a rich information class that holds settings and information about your classes.
///
/// **Some Things to Note**
/// * [classLevel] is set by the developer or user, not automatically retrieved.
/// * [credits] is set by the developer or user, not automatically retrieved.
class Class {
  String name;
  List<String> grades;
  double credits;
  ClassLevel classLevel;

  Class(this.name);

  Class.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        grades = getGradesFromEncodedGradesList(json['grades']),
        credits = json['credits'],
        classLevel = getClassLevelFromText(json['classLevel']);

  Map<String, dynamic> toJson() => {
        'name': name,
        'grades': grades,
        'credits': credits,
        'classLevel': classLevel.toString(),
      };

  static ClassLevel getClassLevelFromText(String txt) {
    try {
      return ClassLevel.values.firstWhere((e) => e.toString() == txt);
    } catch (e) {
      return ClassLevel.Regular;
    }
  }

  static List<String> getGradesFromEncodedGradesList(List grades) {
    List<String> fin = [];
    for (var x in grades) {
      fin.add(x);
    }
    return fin;
  }

  @override
  String toString() {
    return 'GPACalculatorClass{name: $name, grades: $grades, credits: $credits, classLevel: $classLevel}';
  }

  @override
  bool operator ==(other) {
    return name == other.name;
  }

  @override
  int get hashCode => name.hashCode;
}

/// Just ClassLevels, nothing special.
enum ClassLevel { Regular, PreAP, AP, None }
