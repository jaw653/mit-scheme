#| -*-Scheme-*-

Copyright (C) 1986, 1987, 1988, 1989, 1990, 1991, 1992, 1993, 1994,
    1995, 1996, 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
    2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016,
    2017, 2018 Massachusetts Institute of Technology

This file is part of MIT/GNU Scheme.

MIT/GNU Scheme is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or (at
your option) any later version.

MIT/GNU Scheme is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with MIT/GNU Scheme; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301,
USA.

|#

;;;; UCD property: lc (lower-case)

;;; Generated from Unicode 9.0.0

(declare (usual-integrations))

(define (ucd-lc-value char)
  (or (let ((sv (char->integer char)))
        (vector-ref ucd-lc-table-5 (bytevector-u16be-ref ucd-lc-table-4 (fix:lsh (fix:or (fix:lsh (bytevector-u8-ref ucd-lc-table-3 (fix:or (fix:lsh (bytevector-u8-ref ucd-lc-table-2 (fix:or (fix:lsh (bytevector-u8-ref ucd-lc-table-1 (fix:or (fix:lsh (bytevector-u8-ref ucd-lc-table-0 (fix:lsh sv -16)) 4) (fix:and 15 (fix:lsh sv -12)))) 4) (fix:and 15 (fix:lsh sv -8)))) 4) (fix:and 15 (fix:lsh sv -4)))) 4) (fix:and 15 sv)) 1))))
      char))

(define-deferred ucd-lc-table-0
  (vector->bytevector '#(0 1 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2)))

(define-deferred ucd-lc-table-1
  (vector->bytevector '#(0 1 2 3 3 3 3 3 3 3 4 3 3 3 3 5 6 7 3 3 3 3 3 3 3 3 3 3 3 3 8 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3)))

(define-deferred ucd-lc-table-2
  (vector->bytevector '#(0 1 2 3 4 5 6 6 6 6 6 6 6 6 6 6 7 6 6 8 6 6 6 6 6 6 6 6 6 6 9 10 6 11 6 6 12 6 6 6 6 6 6 6 13 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 14 15 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 16 6 6 6 6 17 6 6 6 6 6 6 6 18 6 6 6 6 6 6 6 6 6 6 6 19 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 20 6 6 6 6 6 6)))

(define-deferred ucd-lc-table-3
  (vector->bytevector '#(0 0 0 0 1 2 0 0 0 0 0 0 3 4 0 0 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 26 27 28 29 0 30 31 32 33 34 35 36 0 0 0 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 53 54 55 0 0 0 0 0 0 0 0 0 0 0 0 0 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 0 85 86 87 88 89 90 91 92 0 0 93 94 0 0 95 0 96 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 97 98 0 0 0 99 100 101 0 0 0 102 103 104 105 106 107 108 109 110 111 0 0 0 0 112 113 114 0 115 116 0 0 0 0 0 0 0 0 117 118 119 120 121 122 123 124 125 126 0 0 0 0 0 0 127 128 0 0 0 0 0 0 0 0 0 0 0 0 129 130 131 0 0 0 0 0 0 0 0 132 133 134 0 0 0 0 0 0 0 0 0 0 135 136 137 138 0 0 0 0 0 0 0 0 0 0 0 0 0 0 139 140 0 0 0 0 141 142 143 0 0 0 0 0 0 0 0 0 0 0 0 0)))

(define-deferred ucd-lc-table-4
  (vector->bytevector-u16be
   '#(0    0    0    0    0    0   0    0    0    0    0    0   0    0    0    0    0    1    2    3    4    5    6    7    8    9    10   11   12   13   14   15   16   17   18   19   20   21   22   23   24   25   26   0    0    0    0    0    27   28   29   30   31   32   33   34   35   36   37   38   39   40   41   42   43   44   45   46   47   48   49   0    50   51   52   53   54   55   56   0    57   0    58   0    59   0    60   0    61   0    62   0    63   0    64  0    65  0    66  0    67  0    68   0    69   0    70   0    71   0    72   0    73   0    74   0    75   0    76   0    77   0    78   0    79   0    80   0    81   0    82   0    83   0    84   0    0    85   0   86   0   87   0   88  0   89  0   90  0   91  0    92   0    0    93   0    94   0    95   0    96   0    97   0    98   0    99   0    100  0    101  0    102  0    103  0    104  0    105  0    106  0    107  0    108  0    109  0    110  0    111  0    112  0    113  0    114  0    115  0    116
      117  0    118  0    119  0   0    0    120  121  0    122 0    123  124  0    125  126  127  0    0    128  129  130  131  0    132  133  0    134  135  136  0    0    0    137  138  0    139  140  0    141  0    142  0    143  144  0    145  0    0    146  0    147  148  0    149  150  151  0    152  0    153  154  0    0    0    155  0    0    0    0    0    0    0    156  156  0    157  157  0    158  158  0    159  0    160  0    161  0    162  0    163  0    164 0    165 0    166 0    0   167  0    168  0    169  0    170  0    171  0    172  0    173  0    174  0    175  0    0    176  176  0    177  0    178  179  180  0    181  0    182  0    183  0    184  0    185  0   186  0   187  0   188 0   189 0   190 0   191 0    192  0    193  0    194  0    195  0    196  0    197  0    198  0    199  0    200  0    201  0    202  0    203  0    204  0    205  0    206  0    207  0    208  0    209  0    0    0    0    0    0    0    210  211  0    212  213  0    0    214
      0    215  216  217  218  0   219  0    220  0    221  0   222  0    223  0    224  0    0    0    225  0    0    0    0    0    0    0    0    226  0    0    0    0    0    0    227  0    228  229  230  0    231  0    232  233  0    234  235  236  237  238  239  240  241  242  243  244  245  246  247  248  249  250  0    251  252  253  254  255  256  257  258  259  0    0    0    0    0    0    0    0    0    0    0    0    0    0    0    0    0    0    0    260  0   0    0   0    0   0    0   0    261  0    262  0    263  0    264  0    265  0    266  0    267  0    268  0    269  0    270  0    271  0    272  0    0    0    0    0    241  0    0    273  0    274  275  0    0   276  277 278  279 280 281 282 283 284 285 286 287  288  289  290  291  292  293  294  295  296  297  298  299  300  301  302  303  304  305  306  307  308  309  310  311  312  313  314  315  316  317  318  319  320  321  322  323  324  325  326  327  0    328  0    329  0    330  0    331  0    332
      0    333  0    334  0    335 0    336  0    337  0    338 0    339  0    340  0    341  0    342  0    343  0    0    0    0    0    0    0    0    0    344  0    345  0    346  0    347  0    348  0    349  0    350  0    351  0    352  0    353  0    354  0    355  0    356  0    357  0    358  0    359  0    360  0    361  0    362  0    363  0    364  0    365  0    366  0    367  0    368  0    369  0    370  0    371  372  0    373  0    374  0    375  0    376 0    377 0    378 0    0   379  0    380  0    381  0    382  0    383  0    384  0    385  0    386  0    387  0    388  0    389  0    390  0    391  0    392  0    393  0    394  0    395  0    396  0    397  0   398  0   399  0   400 0   401 0   402 0   403 0    404  0    405  0    406  0    407  0    408  0    409  0    410  0    411  0    412  0    413  0    414  0    415  0    416  0    417  0    418  0    419  0    420  0    421  0    422  0    423  0    424  0    425  0    426  0    0    427  428  429
      430  431  432  433  434  435 436  437  438  439  440  441 442  443  444  445  446  447  448  449  450  451  452  453  454  455  456  457  458  459  460  461  462  463  464  0    0    0    0    0    0    0    0    0    465  466  467  468  469  470  471  472  473  474  475  476  477  478  479  480  481  482  483  484  485  486  487  488  489  490  491  492  493  494  495  496  497  498  499  500  501  502  0    503  0    0    0    0    0    504  0    0    505  506  507 508  509 510  511 512  513 514  515  516  517  518  519  520  521  522  523  524  525  526  527  528  529  530  531  532  533  534  535  536  537  538  539  540  541  542  543  544  545  546  547  548  549  550  551 552  553 554  555 556 557 558 559 560 561 562 563  564  565  566  567  568  569  570  571  572  573  574  575  576  577  578  579  580  581  582  583  584  585  586  587  588  589  590  0    0    0    0    0    0    0    0    0    0    591  0    592  0    593  0    594  0    595  0    596  0    597
      0    598  0    599  0    600 0    601  0    602  0    603 0    604  0    605  0    606  0    607  0    608  0    609  0    610  0    611  0    612  0    613  0    614  0    615  0    616  0    617  0    618  0    619  0    620  0    621  0    622  0    623  0    624  0    625  0    626  0    627  0    628  0    629  0    630  0    631  0    632  0    633  0    634  0    635  0    636  0    637  0    638  0    639  0    640  0    641  0    642  0    643  0    644  0   645  0   646  0   647  0   648  0    649  0    650  0    651  0    652  0    653  0    654  0    655  0    656  0    657  0    658  0    659  0    660  0    661  0    662  0    663  0    664  0    665  0    0    0   0    0   0    0   0   0   666 0   667 0   668 0    669  0    670  0    671  0    672  0    673  0    674  0    675  0    676  0    677  0    678  0    679  0    680  0    681  0    682  0    683  0    684  0    685  0    686  0    687  0    688  0    689  0    690  0    691  0    692  0    693  0
      694  0    695  0    696  0   697  0    698  0    699  0   700  0    701  0    702  0    703  0    704  0    705  0    706  0    707  0    708  0    709  0    710  0    711  0    712  0    713  0    714  0    0    0    0    0    0    0    0    0    715  716  717  718  719  720  721  722  0    0    0    0    0    0    0    0    723  724  725  726  727  728  0    0    0    0    0    0    0    0    0    0    729  730  731  732  733  734  735  736  0    0    0    0    0   0    0   0    737 738  739 740  741  742  743  744  0    0    0    0    0    0    0    0    745  746  747  748  749  750  0    0    0    0    0    0    0    0    0    0    0    751  0    752  0    753  0    754  0   0    0   0    0   0   0   0   755 756 757 758 759  760  761  762  0    0    0    0    0    0    0    0    763  764  765  766  767  768  769  770  0    0    0    0    0    0    0    0    771  772  773  774  775  776  777  778  0    0    0    0    0    0    0    0    779  780  781  782  783  784  785
      786  0    0    0    0    0   0    0    0    787  788  789 790  791  0    0    0    0    0    0    0    0    0    0    0    792  793  794  795  796  0    0    0    0    0    0    0    0    0    0    0    797  798  799  800  0    0    0    0    0    0    0    0    0    0    0    0    801  802  803  804  805  0    0    0    0    0    0    0    0    0    0    0    806  807  808  809  810  0    0    0    0    0    0    0    0    0    257  0    0    0    11   32   0    0   0    0   0    0   811  0   0    0    0    0    0    0    0    0    0    0    0    0    812  813  814  815  816  817  818  819  820  821  822  823  824  825  826  827  0    0    0    828  0    0    0    0    0    0   0    0   0    0   0   0   0   0   0   0   0   0    829  830  831  832  833  834  835  836  837  838  839  840  841  842  843  844  845  846  847  848  849  850  851  852  853  854  855  856  857  858  859  860  861  862  863  864  865  866  867  868  869  870  871  872  873  874  875  876  877  878
      879  880  881  882  883  884 885  886  887  888  889  890 891  892  893  894  895  896  897  898  899  900  901  0    902  0    903  904  905  0    0    906  0    907  0    908  0    909  910  911  912  0    913  0    0    914  0    0    0    0    0    0    0    0    915  916  917  0    918  0    919  0    920  0    921  0    922  0    923  0    924  0    925  0    926  0    927  0    928  0    929  0    930  0    931  0    932  0    933  0    934  0    935  0    936 0    937 0    938 0    939 0    940  0    941  0    942  0    943  0    944  0    945  0    946  0    947  0    948  0    949  0    950  0    951  0    952  0    953  0    954  0    955  0    956  0    957  0    958 0    959 0    960 0   961 0   962 0   963 0   964  0    965  0    966  0    0    0    0    0    0    0    0    967  0    968  0    0    0    0    969  0    0    0    0    0    0    0    0    0    0    0    0    0    970  0    971  0    972  0    973  0    974  0    975  0    976  0    977  0    978
      0    979  0    980  0    981 0    982  0    983  0    984 0    985  0    986  0    987  0    988  0    989  0    990  0    991  0    992  0    0    0    993  0    994  0    995  0    996  0    997  0    998  0    999  0    1000 0    1001 0    1002 0    1003 0    1004 0    1005 0    1006 0    0    0    0    0    0    0    1007 0    1008 0    1009 0    1010 0    1011 0    1012 0    1013 0    0    0    1014 0    1015 0    1016 0    1017 0    1018 0    1019 0    1020 0   1021 0   1022 0   1023 0   1024 0    1025 0    1026 0    1027 0    1028 0    1029 0    1030 0    1031 0    1032 0    1033 0    1034 0    1035 0    1036 0    1037 0    1038 0    1039 0    1040 0    1041 0    1042 0   1043 0   1044 0   0   0   0   0   0   0   0   0    0    1045 0    1046 0    1047 1048 0    1049 0    1050 0    1051 0    1052 0    0    0    0    1053 0    1054 0    0    1055 0    1056 0    0    0    1057 0    1058 0    1059 0    1060 0    1061 0    1062 0    1063 0    1064 0    1065 0    1066 0
      1067 1068 1069 1070 1071 0   1072 1073 1074 1075 1076 0   1077 0    0    0    0    0    0    0    0    0    0    1078 1079 1080 1081 1082 1083 1084 1085 1086 1087 1088 1089 1090 1091 1092 1093 1094 1095 1096 1097 1098 1099 1100 1101 1102 1103 0    0    0    0    0    1104 1105 1106 1107 1108 1109 1110 1111 1112 1113 1114 1115 1116 1117 1118 1119 1120 1121 1122 1123 1124 1125 1126 1127 1128 1129 1130 1131 1132 1133 1134 1135 1136 1137 1138 1139 1140 1141 1142 1143 0   0    0   0    0   0    0   0    1144 1145 1146 1147 1148 1149 1150 1151 1152 1153 1154 1155 1156 1157 1158 1159 1160 1161 1162 1163 1164 1165 1166 1167 1168 1169 1170 1171 1172 1173 1174 1175 1176 1177 1178 1179 0   0    0   0    0   0   0   0   0   0   0   0   1180 1181 1182 1183 1184 1185 1186 1187 1188 1189 1190 1191 1192 1193 1194 1195 1196 1197 1198 1199 1200 1201 1202 1203 1204 1205 1206 1207 1208 1209 1210 1211 1212 1213 1214 1215 1216 1217 1218 1219 1220 1221 1222 1223 1224 1225 1226 1227 1228 1229 1230
      0    0    0    0    0    0   0    0    0    0    0    0   0    1231 1232 1233 1234 1235 1236 1237 1238 1239 1240 1241 1242 1243 1244 1245 1246 1247 1248 1249 1250 1251 1252 1253 1254 1255 1256 1257 1258 1259 1260 1261 1262 1263 1264 1265 1266 1267 1268 1269 1270 1271 1272 1273 1274 1275 1276 1277 1278 1279 1280 1281 1282 1283 1284 1285 1286 1287 1288 1289 1290 1291 1292 1293 1294 1295 1296 0    0    0    0    0    0    0    0    0    0    0    0    0    0)))

(define-deferred ucd-lc-table-5
  (vector-map
   (lambda (converted)
     (and converted
          (if (vector? converted)
              (vector->string converted)
              converted)))
   '#(#f        #\u+61    #\u+62    #\u+63    #\u+64    #\u+65    #\u+66    #\u+67    #\u+68    #\u+69    #\u+6a    #\u+6b    #\u+6c    #\u+6d    #\u+6e    #\u+6f    #\u+70    #\u+71    #\u+72    #\u+73    #\u+74    #\u+75    #\u+76    #\u+77    #\u+78    #\u+79    #\u+7a    #\u+e0    #\u+e1    #\u+e2    #\u+e3    #\u+e4    #\u+e5    #\u+e6    #\u+e7    #\u+e8    #\u+e9    #\u+ea    #\u+eb    #\u+ec    #\u+ed    #\u+ee    #\u+ef    #\u+f0    #\u+f1    #\u+f2    #\u+f3    #\u+f4    #\u+f5    #\u+f6    #\u+f8    #\u+f9    #\u+fa    #\u+fb    #\u+fc    #\u+fd    #\u+fe    #\u+101   #\u+103   #\u+105   #\u+107   #\u+109   #\u+10b   #\u+10d   #\u+10f   #\u+111   #\u+113   #\u+115   #\u+117   #\u+119   #\u+11b   #\u+11d   #\u+11f   #\u+121   #\u+123   #\u+125   #\u+127   #\u+129   #\u+12b   #\u+12d   #\u+12f   #(#\u+69 #\u+307) #\u+133   #\u+135   #\u+137   #\u+13a   #\u+13c   #\u+13e   #\u+140   #\u+142   #\u+144   #\u+146   #\u+148   #\u+14b   #\u+14d   #\u+14f   #\u+151
      #\u+153   #\u+155   #\u+157   #\u+159   #\u+15b   #\u+15d   #\u+15f   #\u+161   #\u+163   #\u+165   #\u+167   #\u+169   #\u+16b   #\u+16d   #\u+16f   #\u+171   #\u+173   #\u+175   #\u+177   #\u+ff    #\u+17a   #\u+17c   #\u+17e   #\u+253   #\u+183   #\u+185   #\u+254   #\u+188   #\u+256   #\u+257   #\u+18c   #\u+1dd   #\u+259   #\u+25b   #\u+192   #\u+260   #\u+263   #\u+269   #\u+268   #\u+199   #\u+26f   #\u+272   #\u+275   #\u+1a1   #\u+1a3   #\u+1a5   #\u+280   #\u+1a8   #\u+283   #\u+1ad   #\u+288   #\u+1b0   #\u+28a   #\u+28b   #\u+1b4   #\u+1b6   #\u+292   #\u+1b9   #\u+1bd   #\u+1c6   #\u+1c9   #\u+1cc   #\u+1ce   #\u+1d0   #\u+1d2   #\u+1d4   #\u+1d6   #\u+1d8   #\u+1da   #\u+1dc   #\u+1df   #\u+1e1   #\u+1e3   #\u+1e5   #\u+1e7   #\u+1e9   #\u+1eb   #\u+1ed   #\u+1ef   #\u+1f3   #\u+1f5   #\u+195           #\u+1bf   #\u+1f9   #\u+1fb   #\u+1fd   #\u+1ff   #\u+201   #\u+203   #\u+205   #\u+207   #\u+209   #\u+20b   #\u+20d   #\u+20f   #\u+211   #\u+213
      #\u+215   #\u+217   #\u+219   #\u+21b   #\u+21d   #\u+21f   #\u+19e   #\u+223   #\u+225   #\u+227   #\u+229   #\u+22b   #\u+22d   #\u+22f   #\u+231   #\u+233   #\u+2c65  #\u+23c   #\u+19a   #\u+2c66  #\u+242   #\u+180   #\u+289   #\u+28c   #\u+247   #\u+249   #\u+24b   #\u+24d   #\u+24f   #\u+371   #\u+373   #\u+377   #\u+3f3   #\u+3ac   #\u+3ad   #\u+3ae   #\u+3af   #\u+3cc   #\u+3cd   #\u+3ce   #\u+3b1   #\u+3b2   #\u+3b3   #\u+3b4   #\u+3b5   #\u+3b6   #\u+3b7   #\u+3b8   #\u+3b9   #\u+3ba   #\u+3bb   #\u+3bc   #\u+3bd   #\u+3be   #\u+3bf   #\u+3c0   #\u+3c1   #\u+3c3   #\u+3c4   #\u+3c5   #\u+3c6   #\u+3c7   #\u+3c8   #\u+3c9   #\u+3ca   #\u+3cb   #\u+3d7   #\u+3d9   #\u+3db   #\u+3dd   #\u+3df   #\u+3e1   #\u+3e3   #\u+3e5   #\u+3e7   #\u+3e9   #\u+3eb   #\u+3ed   #\u+3ef   #\u+3f8   #\u+3f2   #\u+3fb           #\u+37b   #\u+37c   #\u+37d   #\u+450   #\u+451   #\u+452   #\u+453   #\u+454   #\u+455   #\u+456   #\u+457   #\u+458   #\u+459   #\u+45a   #\u+45b
      #\u+45c   #\u+45d   #\u+45e   #\u+45f   #\u+430   #\u+431   #\u+432   #\u+433   #\u+434   #\u+435   #\u+436   #\u+437   #\u+438   #\u+439   #\u+43a   #\u+43b   #\u+43c   #\u+43d   #\u+43e   #\u+43f   #\u+440   #\u+441   #\u+442   #\u+443   #\u+444   #\u+445   #\u+446   #\u+447   #\u+448   #\u+449   #\u+44a   #\u+44b   #\u+44c   #\u+44d   #\u+44e   #\u+44f   #\u+461   #\u+463   #\u+465   #\u+467   #\u+469   #\u+46b   #\u+46d   #\u+46f   #\u+471   #\u+473   #\u+475   #\u+477   #\u+479   #\u+47b   #\u+47d   #\u+47f   #\u+481   #\u+48b   #\u+48d   #\u+48f   #\u+491   #\u+493   #\u+495   #\u+497   #\u+499   #\u+49b   #\u+49d   #\u+49f   #\u+4a1   #\u+4a3   #\u+4a5   #\u+4a7   #\u+4a9   #\u+4ab   #\u+4ad   #\u+4af   #\u+4b1   #\u+4b3   #\u+4b5   #\u+4b7   #\u+4b9   #\u+4bb   #\u+4bd   #\u+4bf   #\u+4cf   #\u+4c2           #\u+4c4   #\u+4c6   #\u+4c8   #\u+4ca   #\u+4cc   #\u+4ce   #\u+4d1   #\u+4d3   #\u+4d5   #\u+4d7   #\u+4d9   #\u+4db   #\u+4dd   #\u+4df   #\u+4e1
      #\u+4e3   #\u+4e5   #\u+4e7   #\u+4e9   #\u+4eb   #\u+4ed   #\u+4ef   #\u+4f1   #\u+4f3   #\u+4f5   #\u+4f7   #\u+4f9   #\u+4fb   #\u+4fd   #\u+4ff   #\u+501   #\u+503   #\u+505   #\u+507   #\u+509   #\u+50b   #\u+50d   #\u+50f   #\u+511   #\u+513   #\u+515   #\u+517   #\u+519   #\u+51b   #\u+51d   #\u+51f   #\u+521   #\u+523   #\u+525   #\u+527   #\u+529   #\u+52b   #\u+52d   #\u+52f   #\u+561   #\u+562   #\u+563   #\u+564   #\u+565   #\u+566   #\u+567   #\u+568   #\u+569   #\u+56a   #\u+56b   #\u+56c   #\u+56d   #\u+56e   #\u+56f   #\u+570   #\u+571   #\u+572   #\u+573   #\u+574   #\u+575   #\u+576   #\u+577   #\u+578   #\u+579   #\u+57a   #\u+57b   #\u+57c   #\u+57d   #\u+57e   #\u+57f   #\u+580   #\u+581   #\u+582   #\u+583   #\u+584   #\u+585   #\u+586   #\u+2d00  #\u+2d01  #\u+2d02  #\u+2d03  #\u+2d04          #\u+2d05  #\u+2d06  #\u+2d07  #\u+2d08  #\u+2d09  #\u+2d0a  #\u+2d0b  #\u+2d0c  #\u+2d0d  #\u+2d0e  #\u+2d0f  #\u+2d10  #\u+2d11  #\u+2d12  #\u+2d13
      #\u+2d14  #\u+2d15  #\u+2d16  #\u+2d17  #\u+2d18  #\u+2d19  #\u+2d1a  #\u+2d1b  #\u+2d1c  #\u+2d1d  #\u+2d1e  #\u+2d1f  #\u+2d20  #\u+2d21  #\u+2d22  #\u+2d23  #\u+2d24  #\u+2d25  #\u+2d27  #\u+2d2d  #\u+ab70  #\u+ab71  #\u+ab72  #\u+ab73  #\u+ab74  #\u+ab75  #\u+ab76  #\u+ab77  #\u+ab78  #\u+ab79  #\u+ab7a  #\u+ab7b  #\u+ab7c  #\u+ab7d  #\u+ab7e  #\u+ab7f  #\u+ab80  #\u+ab81  #\u+ab82  #\u+ab83  #\u+ab84  #\u+ab85  #\u+ab86  #\u+ab87  #\u+ab88  #\u+ab89  #\u+ab8a  #\u+ab8b  #\u+ab8c  #\u+ab8d  #\u+ab8e  #\u+ab8f  #\u+ab90  #\u+ab91  #\u+ab92  #\u+ab93  #\u+ab94  #\u+ab95  #\u+ab96  #\u+ab97  #\u+ab98  #\u+ab99  #\u+ab9a  #\u+ab9b  #\u+ab9c  #\u+ab9d  #\u+ab9e  #\u+ab9f  #\u+aba0  #\u+aba1  #\u+aba2  #\u+aba3  #\u+aba4  #\u+aba5  #\u+aba6  #\u+aba7  #\u+aba8  #\u+aba9  #\u+abaa  #\u+abab  #\u+abac  #\u+abad          #\u+abae  #\u+abaf  #\u+abb0  #\u+abb1  #\u+abb2  #\u+abb3  #\u+abb4  #\u+abb5  #\u+abb6  #\u+abb7  #\u+abb8  #\u+abb9  #\u+abba  #\u+abbb  #\u+abbc
      #\u+abbd  #\u+abbe  #\u+abbf  #\u+13f8  #\u+13f9  #\u+13fa  #\u+13fb  #\u+13fc  #\u+13fd  #\u+1e01  #\u+1e03  #\u+1e05  #\u+1e07  #\u+1e09  #\u+1e0b  #\u+1e0d  #\u+1e0f  #\u+1e11  #\u+1e13  #\u+1e15  #\u+1e17  #\u+1e19  #\u+1e1b  #\u+1e1d  #\u+1e1f  #\u+1e21  #\u+1e23  #\u+1e25  #\u+1e27  #\u+1e29  #\u+1e2b  #\u+1e2d  #\u+1e2f  #\u+1e31  #\u+1e33  #\u+1e35  #\u+1e37  #\u+1e39  #\u+1e3b  #\u+1e3d  #\u+1e3f  #\u+1e41  #\u+1e43  #\u+1e45  #\u+1e47  #\u+1e49  #\u+1e4b  #\u+1e4d  #\u+1e4f  #\u+1e51  #\u+1e53  #\u+1e55  #\u+1e57  #\u+1e59  #\u+1e5b  #\u+1e5d  #\u+1e5f  #\u+1e61  #\u+1e63  #\u+1e65  #\u+1e67  #\u+1e69  #\u+1e6b  #\u+1e6d  #\u+1e6f  #\u+1e71  #\u+1e73  #\u+1e75  #\u+1e77  #\u+1e79  #\u+1e7b  #\u+1e7d  #\u+1e7f  #\u+1e81  #\u+1e83  #\u+1e85  #\u+1e87  #\u+1e89  #\u+1e8b  #\u+1e8d  #\u+1e8f  #\u+1e91          #\u+1e93  #\u+1e95  #\u+df    #\u+1ea1  #\u+1ea3  #\u+1ea5  #\u+1ea7  #\u+1ea9  #\u+1eab  #\u+1ead  #\u+1eaf  #\u+1eb1  #\u+1eb3  #\u+1eb5  #\u+1eb7
      #\u+1eb9  #\u+1ebb  #\u+1ebd  #\u+1ebf  #\u+1ec1  #\u+1ec3  #\u+1ec5  #\u+1ec7  #\u+1ec9  #\u+1ecb  #\u+1ecd  #\u+1ecf  #\u+1ed1  #\u+1ed3  #\u+1ed5  #\u+1ed7  #\u+1ed9  #\u+1edb  #\u+1edd  #\u+1edf  #\u+1ee1  #\u+1ee3  #\u+1ee5  #\u+1ee7  #\u+1ee9  #\u+1eeb  #\u+1eed  #\u+1eef  #\u+1ef1  #\u+1ef3  #\u+1ef5  #\u+1ef7  #\u+1ef9  #\u+1efb  #\u+1efd  #\u+1eff  #\u+1f00  #\u+1f01  #\u+1f02  #\u+1f03  #\u+1f04  #\u+1f05  #\u+1f06  #\u+1f07  #\u+1f10  #\u+1f11  #\u+1f12  #\u+1f13  #\u+1f14  #\u+1f15  #\u+1f20  #\u+1f21  #\u+1f22  #\u+1f23  #\u+1f24  #\u+1f25  #\u+1f26  #\u+1f27  #\u+1f30  #\u+1f31  #\u+1f32  #\u+1f33  #\u+1f34  #\u+1f35  #\u+1f36  #\u+1f37  #\u+1f40  #\u+1f41  #\u+1f42  #\u+1f43  #\u+1f44  #\u+1f45  #\u+1f51  #\u+1f53  #\u+1f55  #\u+1f57  #\u+1f60  #\u+1f61  #\u+1f62  #\u+1f63  #\u+1f64  #\u+1f65          #\u+1f66  #\u+1f67  #\u+1f80  #\u+1f81  #\u+1f82  #\u+1f83  #\u+1f84  #\u+1f85  #\u+1f86  #\u+1f87  #\u+1f90  #\u+1f91  #\u+1f92  #\u+1f93  #\u+1f94
      #\u+1f95  #\u+1f96  #\u+1f97  #\u+1fa0  #\u+1fa1  #\u+1fa2  #\u+1fa3  #\u+1fa4  #\u+1fa5  #\u+1fa6  #\u+1fa7  #\u+1fb0  #\u+1fb1  #\u+1f70  #\u+1f71  #\u+1fb3  #\u+1f72  #\u+1f73  #\u+1f74  #\u+1f75  #\u+1fc3  #\u+1fd0  #\u+1fd1  #\u+1f76  #\u+1f77  #\u+1fe0  #\u+1fe1  #\u+1f7a  #\u+1f7b  #\u+1fe5  #\u+1f78  #\u+1f79  #\u+1f7c  #\u+1f7d  #\u+1ff3  #\u+214e  #\u+2170  #\u+2171  #\u+2172  #\u+2173  #\u+2174  #\u+2175  #\u+2176  #\u+2177  #\u+2178  #\u+2179  #\u+217a  #\u+217b  #\u+217c  #\u+217d  #\u+217e  #\u+217f  #\u+2184  #\u+24d0  #\u+24d1  #\u+24d2  #\u+24d3  #\u+24d4  #\u+24d5  #\u+24d6  #\u+24d7  #\u+24d8  #\u+24d9  #\u+24da  #\u+24db  #\u+24dc  #\u+24dd  #\u+24de  #\u+24df  #\u+24e0  #\u+24e1  #\u+24e2  #\u+24e3  #\u+24e4  #\u+24e5  #\u+24e6  #\u+24e7  #\u+24e8  #\u+24e9  #\u+2c30  #\u+2c31  #\u+2c32          #\u+2c33  #\u+2c34  #\u+2c35  #\u+2c36  #\u+2c37  #\u+2c38  #\u+2c39  #\u+2c3a  #\u+2c3b  #\u+2c3c  #\u+2c3d  #\u+2c3e  #\u+2c3f  #\u+2c40  #\u+2c41
      #\u+2c42  #\u+2c43  #\u+2c44  #\u+2c45  #\u+2c46  #\u+2c47  #\u+2c48  #\u+2c49  #\u+2c4a  #\u+2c4b  #\u+2c4c  #\u+2c4d  #\u+2c4e  #\u+2c4f  #\u+2c50  #\u+2c51  #\u+2c52  #\u+2c53  #\u+2c54  #\u+2c55  #\u+2c56  #\u+2c57  #\u+2c58  #\u+2c59  #\u+2c5a  #\u+2c5b  #\u+2c5c  #\u+2c5d  #\u+2c5e  #\u+2c61  #\u+26b   #\u+1d7d  #\u+27d   #\u+2c68  #\u+2c6a  #\u+2c6c  #\u+251   #\u+271   #\u+250   #\u+252   #\u+2c73  #\u+2c76  #\u+23f   #\u+240   #\u+2c81  #\u+2c83  #\u+2c85  #\u+2c87  #\u+2c89  #\u+2c8b  #\u+2c8d  #\u+2c8f  #\u+2c91  #\u+2c93  #\u+2c95  #\u+2c97  #\u+2c99  #\u+2c9b  #\u+2c9d  #\u+2c9f  #\u+2ca1  #\u+2ca3  #\u+2ca5  #\u+2ca7  #\u+2ca9  #\u+2cab  #\u+2cad  #\u+2caf  #\u+2cb1  #\u+2cb3  #\u+2cb5  #\u+2cb7  #\u+2cb9  #\u+2cbb  #\u+2cbd  #\u+2cbf  #\u+2cc1  #\u+2cc3  #\u+2cc5  #\u+2cc7  #\u+2cc9  #\u+2ccb          #\u+2ccd  #\u+2ccf  #\u+2cd1  #\u+2cd3  #\u+2cd5  #\u+2cd7  #\u+2cd9  #\u+2cdb  #\u+2cdd  #\u+2cdf  #\u+2ce1  #\u+2ce3  #\u+2cec  #\u+2cee  #\u+2cf3
      #\u+a641  #\u+a643  #\u+a645  #\u+a647  #\u+a649  #\u+a64b  #\u+a64d  #\u+a64f  #\u+a651  #\u+a653  #\u+a655  #\u+a657  #\u+a659  #\u+a65b  #\u+a65d  #\u+a65f  #\u+a661  #\u+a663  #\u+a665  #\u+a667  #\u+a669  #\u+a66b  #\u+a66d  #\u+a681  #\u+a683  #\u+a685  #\u+a687  #\u+a689  #\u+a68b  #\u+a68d  #\u+a68f  #\u+a691  #\u+a693  #\u+a695  #\u+a697  #\u+a699  #\u+a69b  #\u+a723  #\u+a725  #\u+a727  #\u+a729  #\u+a72b  #\u+a72d  #\u+a72f  #\u+a733  #\u+a735  #\u+a737  #\u+a739  #\u+a73b  #\u+a73d  #\u+a73f  #\u+a741  #\u+a743  #\u+a745  #\u+a747  #\u+a749  #\u+a74b  #\u+a74d  #\u+a74f  #\u+a751  #\u+a753  #\u+a755  #\u+a757  #\u+a759  #\u+a75b  #\u+a75d  #\u+a75f  #\u+a761  #\u+a763  #\u+a765  #\u+a767  #\u+a769  #\u+a76b  #\u+a76d  #\u+a76f  #\u+a77a  #\u+a77c  #\u+1d79  #\u+a77f  #\u+a781  #\u+a783  #\u+a785          #\u+a787  #\u+a78c  #\u+265   #\u+a791  #\u+a793  #\u+a797  #\u+a799  #\u+a79b  #\u+a79d  #\u+a79f  #\u+a7a1  #\u+a7a3  #\u+a7a5  #\u+a7a7  #\u+a7a9
      #\u+266   #\u+25c   #\u+261   #\u+26c   #\u+26a   #\u+29e   #\u+287   #\u+29d   #\u+ab53  #\u+a7b5  #\u+a7b7  #\u+ff41  #\u+ff42  #\u+ff43  #\u+ff44  #\u+ff45  #\u+ff46  #\u+ff47  #\u+ff48  #\u+ff49  #\u+ff4a  #\u+ff4b  #\u+ff4c  #\u+ff4d  #\u+ff4e  #\u+ff4f  #\u+ff50  #\u+ff51  #\u+ff52  #\u+ff53  #\u+ff54  #\u+ff55  #\u+ff56  #\u+ff57  #\u+ff58  #\u+ff59  #\u+ff5a  #\u+10428 #\u+10429 #\u+1042a #\u+1042b #\u+1042c #\u+1042d #\u+1042e #\u+1042f #\u+10430 #\u+10431 #\u+10432 #\u+10433 #\u+10434 #\u+10435 #\u+10436 #\u+10437 #\u+10438 #\u+10439 #\u+1043a #\u+1043b #\u+1043c #\u+1043d #\u+1043e #\u+1043f #\u+10440 #\u+10441 #\u+10442 #\u+10443 #\u+10444 #\u+10445 #\u+10446 #\u+10447 #\u+10448 #\u+10449 #\u+1044a #\u+1044b #\u+1044c #\u+1044d #\u+1044e #\u+1044f #\u+104d8 #\u+104d9 #\u+104da #\u+104db #\u+104dc         #\u+104dd #\u+104de #\u+104df #\u+104e0 #\u+104e1 #\u+104e2 #\u+104e3 #\u+104e4 #\u+104e5 #\u+104e6 #\u+104e7 #\u+104e8 #\u+104e9 #\u+104ea #\u+104eb
      #\u+104ec #\u+104ed #\u+104ee #\u+104ef #\u+104f0 #\u+104f1 #\u+104f2 #\u+104f3 #\u+104f4 #\u+104f5 #\u+104f6 #\u+104f7 #\u+104f8 #\u+104f9 #\u+104fa #\u+104fb #\u+10cc0 #\u+10cc1 #\u+10cc2 #\u+10cc3 #\u+10cc4 #\u+10cc5 #\u+10cc6 #\u+10cc7 #\u+10cc8 #\u+10cc9 #\u+10cca #\u+10ccb #\u+10ccc #\u+10ccd #\u+10cce #\u+10ccf #\u+10cd0 #\u+10cd1 #\u+10cd2 #\u+10cd3 #\u+10cd4 #\u+10cd5 #\u+10cd6 #\u+10cd7 #\u+10cd8 #\u+10cd9 #\u+10cda #\u+10cdb #\u+10cdc #\u+10cdd #\u+10cde #\u+10cdf #\u+10ce0 #\u+10ce1 #\u+10ce2 #\u+10ce3 #\u+10ce4 #\u+10ce5 #\u+10ce6 #\u+10ce7 #\u+10ce8 #\u+10ce9 #\u+10cea #\u+10ceb #\u+10cec #\u+10ced #\u+10cee #\u+10cef #\u+10cf0 #\u+10cf1 #\u+10cf2 #\u+118c0 #\u+118c1 #\u+118c2 #\u+118c3 #\u+118c4 #\u+118c5 #\u+118c6 #\u+118c7 #\u+118c8 #\u+118c9 #\u+118ca #\u+118cb #\u+118cc #\u+118cd #\u+118ce         #\u+118cf #\u+118d0 #\u+118d1 #\u+118d2 #\u+118d3 #\u+118d4 #\u+118d5 #\u+118d6 #\u+118d7 #\u+118d8 #\u+118d9 #\u+118da #\u+118db #\u+118dc #\u+118dd
      #\u+118de #\u+118df #\u+1e922 #\u+1e923 #\u+1e924 #\u+1e925 #\u+1e926 #\u+1e927 #\u+1e928 #\u+1e929 #\u+1e92a #\u+1e92b #\u+1e92c #\u+1e92d #\u+1e92e #\u+1e92f #\u+1e930 #\u+1e931 #\u+1e932 #\u+1e933 #\u+1e934 #\u+1e935 #\u+1e936 #\u+1e937 #\u+1e938 #\u+1e939 #\u+1e93a #\u+1e93b #\u+1e93c #\u+1e93d #\u+1e93e #\u+1e93f #\u+1e940 #\u+1e941 #\u+1e942 #\u+1e943)))