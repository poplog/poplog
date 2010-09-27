
;;; Illness is an example which shows how to declare a file format with
;;; a number of different fields, including an N-of-M field. You can
;;; create a network based on the "ill_eg" example set and train it once
;;; this file has been loaded. The 'expert' diagnosis is made using the
;;; patient's symptoms and temperature.
;;;

;;; declare the type of data used for the diagnosis
;;;
nn_declare_range("temperature", 35, 40);
nn_declare_set("symptom", [coughs sneezes aches], 0.7);

;;; declare possible outcomes
;;;
nn_declare_set("illness", [cold flu none]);

;;; since we can have more than 1 symptom at a time, we need to define
;;; a format. In this case, the field is delimited by "(" and ")", and
;;; each symptom is separated by ","
;;;
nn_declare_field_format("symptoms", "symptom", "(", ")", ",");

;;; declare the example set, including the source type (from a file),
;;; and the file name, and also where results are sent when the example
;;; set is applied to a network (to a file called 'results.dat')
;;;
nn_make_egs("ill_eg", [[in symptoms Symptoms]
                       [in temperature Temperature]
                       [out illness Illness]],
                EG_FILE, '$popneural/demos/Illnesses/symptoms.dat',
                EG_FILE, 'results.dat', eg_default_flags);

;;; read the symptoms.dat file and convert the data to numbers ready
;;; for training/testing
;;;
nn_generate_egs("ill_eg");
