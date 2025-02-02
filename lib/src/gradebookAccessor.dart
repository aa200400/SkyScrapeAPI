import 'dart:convert';
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';
import '../data_types.dart';
import 'skywardUniversal.dart';

class GradebookAccessor {
  /*
  This decoded json string is super weird. Look at initGradebookHTML if you need to understand it.
   */
  static final _termJsonDeliminater =
      "sff.sv('sf_gridObjects',\$.extend((sff.getValue('sf_gridObjects') ";

  static getTermsFromDocCode(List infoList) {
    List<Term> terms = [];
    for (var termHTMLA in infoList[0]) {
      String termHTML = termHTMLA['h'];
      termHTML =
          termHTML.replaceFirst('th', 'a').substring(0, termHTML.length - 4) +
              'a>';

      final termDoc = DocumentFragment.html(termHTML);
      final tooltip = termDoc.querySelector('a').attributes['tooltip'];

      if (tooltip != null) terms.add(Term(termDoc.text, tooltip));
    }
    return terms;
  }

  static getGradeBoxesFromDocCode(List infoList, List<Term> terms) {
    List<GridBox> gradeBoxes = [];
    var parsedHTML = parse(infoList[2]);
    for (var sffBrak in infoList[1]) {
      for (var i = 0; i < sffBrak['c'].length; i++) {
        var c = sffBrak['c'][i];
        var cDoc = DocumentFragment.html(c['h']);
        Element gradeElem = cDoc.getElementById('showGradeInfo');
        Element assignmentInfoElem = cDoc.getElementById('showAssignmentInfo');
        if (assignmentInfoElem != null) {
          int grade;
          for (var index = i + 1; index < sffBrak['c'].length; index++) {
            var frag = DocumentFragment.html(sffBrak['c'][index]['h']);
            int attemptedParse = int.tryParse(frag.text);
            if (attemptedParse != null) {
              grade = attemptedParse;
            }
          }
          String assignmentLabels = cDoc.querySelectorAll('span')[0].text;
          Assignment temp = Assignment(
              assignmentInfoElem.attributes['data-sid'],
              assignmentInfoElem.attributes['data-aid'],
              assignmentInfoElem.attributes['data-gid'],
              cDoc.querySelectorAll('a')[0].text,
              Map.fromIterables([
                'term',
                'grade'
              ], [
                assignmentLabels.substring(assignmentLabels.indexOf('('),
                    assignmentLabels.indexOf(')')),
                grade.toString()
              ]));

          if (!(gradeBoxes.length < 1 ||
              gradeBoxes.last is AssignmentsListSmaller)) {
            gradeBoxes.add(AssignmentsListSmaller());
          }
          (gradeBoxes.last as AssignmentsListSmaller).assignments.add(temp);
          break;
        } else if (gradeElem != null) {
          GradeBox x = GradeBox(
              gradeElem.attributes['data-cni'],
              Term(gradeElem.attributes['data-lit'],
                  gradeElem.attributes['data-bkt']),
              gradeElem.text,
              gradeElem.attributes['data-sid']);
          x.clickable = true;
          gradeBoxes.add(x);
        } else if (c['cId'] != null) {
          var tdElement = parsedHTML.getElementById(c['cId']);
          var tdElements = (tdElement.children[0].querySelectorAll('td'));
          gradeBoxes.add(TeacherIDBox(
              tdElements[3].text, tdElements[1].text, tdElements[2].text));
        } else if (cDoc.text.trim().isNotEmpty) {
          gradeBoxes.add(LessInfoBox(cDoc.text, terms[i - 1]));
        }
      }
    }
    return gradeBoxes;
  }

  static List initGradebookAndGradesHTML(String html) {
    Document doc = parse(html);

    if (!didSessionExpire(html)) {
      Element elem = doc.querySelector("script[data-rel='sff']");
      if (elem.text.contains(_termJsonDeliminater)) {
        var needToDecodeJson = elem.text.substring(
            elem.text.indexOf(_termJsonDeliminater) +
                _termJsonDeliminater.length,
            elem.text.length - 5);
        needToDecodeJson =
            needToDecodeJson.substring(needToDecodeJson.indexOf(':') + 1);
        var mapOfFutureParsedHTML = jsonDecode(needToDecodeJson);

        return [
          mapOfFutureParsedHTML['th']['r'][0]['c'],
          mapOfFutureParsedHTML['tb']['r'],
          html
        ];
      }
    } else {
      throw SkywardError('Session Expired');
    }

    return [];
  }
}
