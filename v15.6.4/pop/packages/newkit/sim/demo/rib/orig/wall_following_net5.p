;;; FILE CREATED BY STOREDATA

;;; Instruction to read in rest of file and create database
[% until null(proglist) do
	 if hd(proglist) == "[" then listread()
	 else readitem()
	 endif
	enduntil
%] -> database;

[network [wall_following_net [user_interactor rib_interactor]]]
[number_of_examples wall_following_net 1304]
[prudence 0.5]
[network [wall_following_net [network_type backpropagation]]]
[network [wall_following_net [epsilon 1]]]
[network [wall_following_net [random_scale 0.1]]]
[network [wall_following_net [already_taught]]]
[network [wall_following_net [iterations_number 1000 1000 1000]]]
[network [wall_following_net [tss 1.09391]]]
[network [wall_following_net [tss_limit 0.001]]]
[network [wall_following_net [unit vx input sigmoid 0 0 0 0]]]
[network [wall_following_net [unit vy input sigmoid 0 0 0 0]]]
[network [wall_following_net [unit s0 input sigmoid 0 0 0 0]]]
[network [wall_following_net [unit s45 input sigmoid 0 0 0 0]]]
[network [wall_following_net [unit s90 input sigmoid 0 0 0 0]]]
[network [wall_following_net [unit s135 input sigmoid 0 0 0 0]]]
[network [wall_following_net [unit s180 input sigmoid 0 0 0 0]]]
[network [wall_following_net [unit s225 input sigmoid 0 0 0 0]]]
[network [wall_following_net [unit s270 input sigmoid 0 0 0 0]]]
[network [wall_following_net [unit s315 input sigmoid 0 0 0 0]]]
[network [wall_following_net [unit hid1 hidden sigmoid 0 0 0 -6.60755]]]
[network [wall_following_net [unit hid2 hidden sigmoid 0 0 0 -7.95852]]]
[network [wall_following_net [unit hid3 hidden sigmoid 0 0 0 -5.16184]]]
[network [wall_following_net [unit hid4 hidden sigmoid 0 0 0 -4.49216]]]
[network [wall_following_net [unit hid5 hidden sigmoid 0 0 0 -10.0618]]]
[network [wall_following_net [unit hid6 hidden sigmoid 0 0 0 -3.27062]]]
[network [wall_following_net [unit hid7 hidden sigmoid 0 0 0 -6.17249]]]
[network [wall_following_net [unit hid8 hidden sigmoid 0 0 0 -0.669802]]]
[network [wall_following_net [unit hid9 hidden sigmoid 0 0 0 -3.853]]]
[network [wall_following_net [unit hid10 hidden sigmoid 0 0 0 -3.64311]]]
[network [wall_following_net [unit ax output sigmoid 0 0 0 0.141148]]]
[network [wall_following_net [unit ay output sigmoid 0 0 0 0.059711]]]
[network [wall_following_net [connection hid1 [s0 s45 s90 s135 s180 s225 s270 s315 vx vy] [-9.76561 -2.50229 -0.683223 4.39233 1.65536 -5.70715 7.98716 6.53387 -7.14152 -0.062346]]]]
[network [wall_following_net [connection hid2 [s0 s45 s90 s135 s180 s225 s270 s315 vx vy] [-6.65232 3.24245 -0.058204 4.74465 -2.72697 3.60912 5.37343 1.46272 11.5197 -5.24728]]]]
[network [wall_following_net [connection hid3 [s0 s45 s90 s135 s180 s225 s270 s315 vx vy] [-2.0617 7.56035 3.01422 -3.46583 -1.73969 11.785 -7.2023 -2.48849 0.366625 1.47064]]]]
[network [wall_following_net [connection hid4 [s0 s45 s90 s135 s180 s225 s270 s315 vx vy] [2.57591 -11.9923 17.2947 1.04707 -14.0294 -0.68774 3.99187 11.8849 5.51283 1.07625]]]]
[network [wall_following_net [connection hid5 [s0 s45 s90 s135 s180 s225 s270 s315 vx vy] [-4.60893 9.68056 2.69316 2.88245 1.04207 8.33268 -1.07976 -0.524123 -3.92323 9.72734]]]]
[network [wall_following_net [connection hid6 [s0 s45 s90 s135 s180 s225 s270 s315 vx vy] [1.8728 -1.29978 -4.95859 -0.617939 -0.928202 2.82443 -0.244241 -2.97372 3.82727 27.1123]]]]
[network [wall_following_net [connection hid7 [s0 s45 s90 s135 s180 s225 s270 s315 vx vy] [3.1733 -5.79059 -3.26095 9.0703 -6.8273 -6.10824 9.44549 -3.73538 -20.5882 9.06818]]]]
[network [wall_following_net [connection hid8 [s0 s45 s90 s135 s180 s225 s270 s315 vx vy] [-2.2557 -0.87794 1.59909 -6.00038 -1.0042 3.64614 -2.06068 -1.58912 9.01521 -9.68156]]]]
[network [wall_following_net [connection hid9 [s0 s45 s90 s135 s180 s225 s270 s315 vx vy] [0.607022 -3.87469 -1.28751 0.573758 3.14436 -4.65316 0.884741 1.67946 12.1052 6.66163]]]]
[network [wall_following_net [connection hid10 [s0 s45 s90 s135 s180 s225 s270 s315 vx vy] [1.99738 -2.52996 0.193929 1.18704 -3.54298 3.93179 -1.33016 -0.277606 -5.25301 -5.92017]]]]
[network [wall_following_net [connection ax [hid1 hid2 hid3 hid4 hid5 hid6 hid7 hid8 hid9 hid10] [1.07006 -2.98458 -0.672061 -0.201309 0.849293 -6.28495 6.8044 1.38914 -5.14957 3.24073]]]]
[network [wall_following_net [connection ay [hid1 hid2 hid3 hid4 hid5 hid6 hid7 hid8 hid9 hid10] [-0.290224 0.967176 -0.02786 -0.170044 -0.457602 -7.39155 -3.51529 1.15638 1.72924 3.55404]]]]
