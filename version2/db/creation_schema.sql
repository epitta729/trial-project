--
-- PostgreSQL database dump
--

-- Dumped from database version 9.4.26
-- Dumped by pg_dump version 9.4.26
-- Started on 2024-12-07 20:45:43

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;

--
-- TOC entry 8 (class 2615 OID 16394)
-- Name: main; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA main;


ALTER SCHEMA main OWNER TO postgres;

--
-- TOC entry 198 (class 1255 OID 16490)
-- Name: get_max_withdrawal_last_month(bigint); Type: FUNCTION; Schema: main; Owner: postgres
--

CREATE FUNCTION main.get_max_withdrawal_last_month(beneficiary_id bigint) RETURNS TABLE(transactionid bigint, accountid bigint, amount numeric, transaction_date date)
    LANGUAGE plpgsql
    AS $$
DECLARE
    last_trans_date DATE;
    first_day_of_month DATE;
    last_day_of_month DATE;
BEGIN

	
    -- latest transaction of the beneficiary
    select MAX(t.trans_date)
    into last_trans_date
    from main.transactions t,main.accounts a 
    where t.accountid = a.accountid and a.beneficiaryid = beneficiary_id;

    if last_trans_date is null then
        return; -- No transactions
    end if;

    -- first and last day of latest months' transaction
    first_day_of_month := date_trunc('month', last_trans_date);
    last_day_of_month := (first_day_of_month + interval '1 month' - interval '1 day')::DATE;

    -- Find the max withdrawal of that month for the requested beneficiary
    RETURN QUERY
    select t.transactionid, t.accountid, t.amount, t.trans_date
    from main.transactions t, main.accounts a 
    WHERE t.accountid = a.accountid 
	and a.beneficiaryid = beneficiary_id
	and t.type = 'withdrawal'
	and t.trans_date between first_day_of_month and last_day_of_month
    order by t.amount desc
    limit 1;
END;
$$;


ALTER FUNCTION main.get_max_withdrawal_last_month(beneficiary_id bigint) OWNER TO postgres;

--
-- TOC entry 199 (class 1255 OID 16492)
-- Name: getbalance(bigint); Type: FUNCTION; Schema: main; Owner: postgres
--

CREATE FUNCTION main.getbalance(beneficiary_id bigint) RETURNS TABLE(accountid bigint, balance numeric)
    LANGUAGE plpgsql
    AS $$
  
BEGIN
	RETURN QUERY
	select 	t.accountid
		,greatest(SUM(case WHEN t.type = 'deposit' THEN t.amount 
			WHEN t.type = 'withdrawal' THEN -t.amount 
                ELSE 0 END),0) AS balance
	from main.transactions t,main.accounts a 
	where t.accountid = a.accountid and a.beneficiaryid = beneficiary_id
	group by t.accountid;


END;
$$;


ALTER FUNCTION main.getbalance(beneficiary_id bigint) OWNER TO postgres;

--
-- TOC entry 196 (class 1255 OID 16485)
-- Name: getben_accounts(bigint); Type: FUNCTION; Schema: main; Owner: postgres
--

CREATE FUNCTION main.getben_accounts(beneficiary_id bigint) RETURNS TABLE(accountid bigint)
    LANGUAGE plpgsql
    AS $$
   
BEGIN
	RETURN QUERY
	select a.accountid
	from main.accounts a
	where a.beneficiaryid=beneficiary_id;

END;
$$;


ALTER FUNCTION main.getben_accounts(beneficiary_id bigint) OWNER TO postgres;

--
-- TOC entry 197 (class 1255 OID 16487)
-- Name: getben_transactions(bigint); Type: FUNCTION; Schema: main; Owner: postgres
--

CREATE FUNCTION main.getben_transactions(beneficiary_id bigint) RETURNS TABLE(accountid bigint, amount numeric, type character varying, trans_date date)
    LANGUAGE plpgsql
    AS $$
   
BEGIN
	RETURN QUERY
	select a.accountid,t.amount,t.type,t.trans_date
	from main.transactions t,main.accounts a
	where t.accountid=a.accountid 
		and a.beneficiaryid=beneficiary_id;

END;
$$;


ALTER FUNCTION main.getben_transactions(beneficiary_id bigint) OWNER TO postgres;

--
-- TOC entry 195 (class 1255 OID 16484)
-- Name: getbeninfo(bigint); Type: FUNCTION; Schema: main; Owner: postgres
--

CREATE FUNCTION main.getbeninfo(beneficiary_id bigint) RETURNS TABLE(firstname character varying, lastname character varying)
    LANGUAGE plpgsql
    AS $$
   
BEGIN
	RETURN QUERY
	select b.firstname,b.lastname 
	from main.beneficiaries b
	where b.beneficiaryid=beneficiary_id;

END;
$$;


ALTER FUNCTION main.getbeninfo(beneficiary_id bigint) OWNER TO postgres;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 177 (class 1259 OID 16439)
-- Name: accounts; Type: TABLE; Schema: main; Owner: postgres; Tablespace: 
--

CREATE TABLE main.accounts (
    accountid bigint NOT NULL,
    beneficiaryid bigint NOT NULL
);


ALTER TABLE main.accounts OWNER TO postgres;

--
-- TOC entry 176 (class 1259 OID 16437)
-- Name: accounts_accountid_seq; Type: SEQUENCE; Schema: main; Owner: postgres
--

CREATE SEQUENCE main.accounts_accountid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE main.accounts_accountid_seq OWNER TO postgres;

--
-- TOC entry 2045 (class 0 OID 0)
-- Dependencies: 176
-- Name: accounts_accountid_seq; Type: SEQUENCE OWNED BY; Schema: main; Owner: postgres
--

ALTER SEQUENCE main.accounts_accountid_seq OWNED BY main.accounts.accountid;


--
-- TOC entry 175 (class 1259 OID 16431)
-- Name: beneficiaries; Type: TABLE; Schema: main; Owner: postgres; Tablespace: 
--

CREATE TABLE main.beneficiaries (
    beneficiaryid bigint NOT NULL,
    firstname character varying(50),
    lastname character varying(50)
);


ALTER TABLE main.beneficiaries OWNER TO postgres;

--
-- TOC entry 174 (class 1259 OID 16429)
-- Name: beneficiaries_beneficiaryid_seq; Type: SEQUENCE; Schema: main; Owner: postgres
--

CREATE SEQUENCE main.beneficiaries_beneficiaryid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE main.beneficiaries_beneficiaryid_seq OWNER TO postgres;

--
-- TOC entry 2046 (class 0 OID 0)
-- Dependencies: 174
-- Name: beneficiaries_beneficiaryid_seq; Type: SEQUENCE OWNED BY; Schema: main; Owner: postgres
--

ALTER SEQUENCE main.beneficiaries_beneficiaryid_seq OWNED BY main.beneficiaries.beneficiaryid;


--
-- TOC entry 179 (class 1259 OID 16453)
-- Name: transactions; Type: TABLE; Schema: main; Owner: postgres; Tablespace: 
--

CREATE TABLE main.transactions (
    transactionid bigint NOT NULL,
    accountid bigint NOT NULL,
    amount numeric(10,2) NOT NULL,
    type character varying(20) NOT NULL,
    trans_date date NOT NULL,
    CONSTRAINT transactions_amount_check CHECK ((amount >= (0)::numeric)),
    CONSTRAINT transactions_type_check CHECK (((type)::text = ANY (ARRAY[('withdrawal'::character varying)::text, ('deposit'::character varying)::text])))
);


ALTER TABLE main.transactions OWNER TO postgres;

--
-- TOC entry 178 (class 1259 OID 16451)
-- Name: transactions_transactionid_seq; Type: SEQUENCE; Schema: main; Owner: postgres
--

CREATE SEQUENCE main.transactions_transactionid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE main.transactions_transactionid_seq OWNER TO postgres;

--
-- TOC entry 2047 (class 0 OID 0)
-- Dependencies: 178
-- Name: transactions_transactionid_seq; Type: SEQUENCE OWNED BY; Schema: main; Owner: postgres
--

ALTER SEQUENCE main.transactions_transactionid_seq OWNED BY main.transactions.transactionid;


--
-- TOC entry 1911 (class 2604 OID 16442)
-- Name: accountid; Type: DEFAULT; Schema: main; Owner: postgres
--

ALTER TABLE ONLY main.accounts ALTER COLUMN accountid SET DEFAULT nextval('main.accounts_accountid_seq'::regclass);


--
-- TOC entry 1910 (class 2604 OID 16434)
-- Name: beneficiaryid; Type: DEFAULT; Schema: main; Owner: postgres
--

ALTER TABLE ONLY main.beneficiaries ALTER COLUMN beneficiaryid SET DEFAULT nextval('main.beneficiaries_beneficiaryid_seq'::regclass);


--
-- TOC entry 1912 (class 2604 OID 16456)
-- Name: transactionid; Type: DEFAULT; Schema: main; Owner: postgres
--

ALTER TABLE ONLY main.transactions ALTER COLUMN transactionid SET DEFAULT nextval('main.transactions_transactionid_seq'::regclass);


--
-- TOC entry 2037 (class 0 OID 16439)
-- Dependencies: 177
-- Data for Name: accounts; Type: TABLE DATA; Schema: main; Owner: postgres
--

COPY main.accounts (accountid, beneficiaryid) FROM stdin;
1	79
2	183
3	334
4	640
5	360
6	405
7	885
8	866
9	276
10	980
11	821
12	694
13	652
14	573
15	934
16	400
17	151
18	750
19	657
20	261
21	181
22	691
23	669
24	58
25	917
26	410
27	217
28	321
29	282
30	370
31	804
32	136
33	328
34	203
35	578
36	895
37	726
38	640
39	294
40	695
41	252
42	400
43	583
44	243
45	554
46	554
47	903
48	909
49	628
50	75
51	872
52	645
53	954
54	62
55	119
56	260
57	722
58	842
59	989
60	279
61	270
62	720
63	650
64	616
65	29
66	544
67	772
68	194
69	604
70	953
71	241
72	911
73	929
74	392
75	223
76	486
77	881
78	517
79	201
80	942
81	88
82	145
83	990
84	817
85	214
86	784
87	576
88	134
89	317
90	602
91	342
92	322
93	602
94	569
95	487
96	78
97	469
98	961
99	11
100	43
101	11
102	365
103	756
104	248
105	19
106	603
107	271
108	288
109	605
110	902
111	590
112	989
113	345
114	320
115	297
116	811
117	492
118	841
119	132
120	32
121	368
122	544
123	955
124	371
125	920
126	831
127	571
128	703
129	48
130	186
131	474
132	449
133	495
134	209
135	336
136	958
137	21
138	900
139	177
140	83
141	655
142	879
143	742
144	902
145	655
146	128
147	721
148	933
149	33
150	275
151	478
152	424
153	203
154	518
155	400
156	378
157	273
158	243
159	220
160	188
161	409
162	954
163	552
164	373
165	93
166	447
167	770
168	704
169	77
170	806
171	873
172	429
173	444
174	54
175	14
176	788
177	734
178	85
179	986
180	13
181	412
182	93
183	348
184	109
185	888
186	24
187	89
188	122
189	245
190	415
191	691
192	241
193	94
194	214
195	269
196	983
197	120
198	652
199	796
200	351
201	619
202	498
203	615
204	69
205	9
206	280
207	219
208	570
209	766
210	918
211	777
212	262
213	492
214	347
215	253
216	951
217	400
218	427
219	18
220	45
221	832
222	527
223	404
224	425
225	254
226	811
227	608
228	394
229	438
230	242
231	224
232	487
233	487
234	74
235	396
236	105
237	930
238	893
239	618
240	91
241	265
242	443
243	556
244	640
245	463
246	20
247	321
248	636
249	244
250	465
251	233
252	311
253	475
254	68
255	86
256	188
257	26
258	912
259	48
260	906
261	183
262	251
263	669
264	585
265	782
266	212
267	933
268	22
269	924
270	465
271	492
272	675
273	332
274	9
275	450
276	551
277	279
278	79
279	986
280	70
281	715
282	939
283	23
284	47
285	332
286	800
287	245
288	898
289	772
290	220
291	610
292	48
293	299
294	563
295	621
296	686
297	510
298	770
299	235
300	68
301	294
302	805
303	770
304	324
305	657
306	221
307	423
308	548
309	819
310	783
311	359
312	986
313	699
314	209
315	297
316	34
317	37
318	108
319	985
320	387
321	768
322	759
323	872
324	62
325	504
326	859
327	595
328	703
329	37
330	288
331	994
332	649
333	26
334	662
335	181
336	571
337	744
338	627
339	110
340	614
341	355
342	928
343	946
344	210
345	855
346	815
347	554
348	402
349	727
350	827
351	993
352	235
353	314
354	481
355	919
356	386
357	92
358	380
359	544
360	601
361	16
362	894
363	641
364	543
365	85
366	989
367	152
368	483
369	864
370	338
371	190
372	819
373	633
374	677
375	154
376	116
377	788
378	9
379	591
380	769
381	542
382	194
383	704
384	953
385	73
386	35
387	754
388	972
389	387
390	383
391	759
392	388
393	994
394	560
395	81
396	198
397	751
398	899
399	491
400	215
401	818
402	260
403	277
404	778
405	220
406	272
407	490
408	793
409	439
410	756
411	646
412	873
413	340
414	708
415	121
416	188
417	868
418	820
419	786
420	550
421	848
422	220
423	739
424	97
425	679
426	401
427	96
428	933
429	601
430	557
431	640
432	986
433	551
434	999
435	107
436	476
437	289
438	945
439	94
440	194
441	626
442	351
443	348
444	488
445	248
446	314
447	775
448	752
449	46
450	134
451	153
452	144
453	136
454	215
455	321
456	23
457	444
458	187
459	816
460	588
461	745
462	995
463	796
464	571
465	235
466	104
467	464
468	780
469	31
470	550
471	991
472	79
473	518
474	740
475	403
476	353
477	935
478	649
479	401
480	383
481	832
482	319
483	773
484	126
485	781
486	282
487	665
488	779
489	662
490	643
491	115
492	491
493	658
494	85
495	635
496	157
497	5
498	264
499	643
500	630
501	90
502	368
503	970
504	893
505	987
506	273
507	738
508	766
509	726
510	606
511	796
512	464
513	13
514	345
515	839
516	683
517	743
518	921
519	444
520	594
521	712
522	194
523	533
524	575
525	162
526	214
527	924
528	126
529	389
530	320
531	378
532	57
533	526
534	510
535	996
536	404
537	404
538	247
539	572
540	880
541	40
542	368
543	702
544	670
545	315
546	633
547	845
548	231
549	336
550	823
551	990
552	214
553	185
554	760
555	899
556	695
557	614
558	140
559	509
560	356
561	416
562	396
563	678
564	797
565	511
566	150
567	726
568	72
569	860
570	321
571	273
572	421
573	814
574	363
575	101
576	508
577	970
578	704
579	672
580	840
581	740
582	694
583	223
584	824
585	771
586	933
587	621
588	108
589	17
590	51
591	396
592	869
593	810
594	495
595	600
596	619
597	144
598	992
599	579
600	708
601	262
602	518
603	882
604	981
605	839
606	198
607	291
608	402
609	132
610	423
611	929
612	386
613	87
614	479
615	44
616	152
617	115
618	443
619	873
620	510
621	471
622	314
623	921
624	553
625	651
626	164
627	617
628	2
629	798
630	543
631	921
632	916
633	108
634	15
635	111
636	615
637	737
638	319
639	800
640	444
641	685
642	606
643	178
644	996
645	818
646	801
647	637
648	853
649	852
650	161
651	251
652	62
653	775
654	140
655	623
656	546
657	739
658	74
659	695
660	297
661	640
662	505
663	264
664	654
665	437
666	758
667	457
668	852
669	874
670	229
671	8
672	992
673	648
674	968
675	878
676	19
677	497
678	522
679	425
680	791
681	323
682	102
683	4
684	764
685	510
686	872
687	104
688	781
689	544
690	723
691	553
692	434
693	220
694	45
695	273
696	831
697	650
698	501
699	670
700	468
701	927
702	604
703	252
704	534
705	82
706	330
707	87
708	984
709	317
710	969
711	734
712	144
713	247
714	36
715	586
716	260
717	957
718	133
719	390
720	121
721	765
722	232
723	706
724	621
725	141
726	335
727	876
728	242
729	712
730	260
731	582
732	665
733	393
734	436
735	884
736	285
737	686
738	905
739	841
740	799
741	249
742	84
743	144
744	28
745	49
746	392
747	493
748	149
749	286
750	552
751	811
752	219
753	316
754	423
755	691
756	16
757	929
758	375
759	499
760	684
761	498
762	941
763	319
764	346
765	647
766	6
767	291
768	706
769	316
770	910
771	52
772	873
773	392
774	131
775	192
776	159
777	599
778	508
779	47
780	111
781	74
782	903
783	958
784	831
785	283
786	993
787	249
788	667
789	693
790	160
791	912
792	712
793	698
794	867
795	492
796	432
797	386
798	422
799	808
800	337
801	940
802	931
803	91
804	727
805	623
806	747
807	75
808	496
809	375
810	35
811	169
812	544
813	92
814	599
815	231
816	508
817	428
818	285
819	586
820	507
821	630
822	430
823	372
824	522
825	331
826	31
827	410
828	31
829	898
830	60
831	798
832	668
833	949
834	560
835	670
836	851
837	250
838	117
839	788
840	307
841	862
842	747
843	558
844	820
845	449
846	528
847	670
848	522
849	422
850	878
851	978
852	213
853	464
854	935
855	251
856	377
857	200
858	409
859	945
860	513
861	289
862	150
863	176
864	121
865	993
866	102
867	116
868	99
869	446
870	804
871	879
872	512
873	236
874	624
875	723
876	271
877	315
878	295
879	624
880	453
881	492
882	541
883	258
884	956
885	554
886	411
887	39
888	356
889	791
890	62
891	382
892	119
893	1000
894	534
895	775
896	821
897	671
898	407
899	204
900	154
901	600
902	781
903	328
904	776
905	612
906	706
907	89
908	373
909	4
910	419
911	779
912	260
913	330
914	381
915	879
916	739
917	472
918	67
919	15
920	503
921	115
922	828
923	754
924	662
925	775
926	163
927	349
928	777
929	404
930	631
931	339
932	634
933	965
934	611
935	502
936	646
937	199
938	587
939	909
940	172
941	529
942	61
943	974
944	872
945	998
946	501
947	901
948	667
949	247
950	776
951	627
952	311
953	696
954	285
955	591
956	213
957	367
958	850
959	395
960	628
961	687
962	273
963	390
964	671
965	243
966	422
967	422
968	247
969	236
970	900
971	396
972	239
973	482
974	988
975	729
976	473
977	959
978	584
979	303
980	114
981	917
982	264
983	203
984	94
985	903
986	628
987	414
988	47
989	834
990	364
991	318
992	655
993	825
994	641
995	268
996	116
997	157
998	97
999	29
1000	24
1001	176
1002	539
1003	2
1004	418
1005	874
1006	540
1007	321
1008	973
1009	824
1010	963
1011	640
1012	479
1013	559
1014	306
1015	709
1016	928
1017	897
1018	438
1019	825
1020	795
1021	982
1022	482
1023	820
1024	868
1025	141
1026	408
1027	68
1028	39
1029	836
1030	246
1031	554
1032	188
1033	385
1034	504
1035	234
1036	316
1037	484
1038	663
1039	763
1040	180
1041	110
1042	278
1043	530
1044	527
1045	173
1046	525
1047	847
1048	110
1049	953
1050	679
1051	7
1052	421
1053	27
1054	403
1055	760
1056	417
1057	144
1058	271
1059	803
1060	394
1061	910
1062	227
1063	800
1064	788
1065	170
1066	421
1067	262
1068	315
1069	21
1070	662
1071	893
1072	968
1073	517
1074	557
1075	966
1076	86
1077	581
1078	25
1079	284
1080	866
1081	881
1082	240
1083	152
1084	459
1085	545
1086	8
1087	670
1088	603
1089	521
1090	895
1091	963
1092	259
1093	950
1094	155
1095	960
1096	690
1097	774
1098	568
1099	330
1100	587
1101	860
1102	70
1103	826
1104	19
1105	732
1106	517
1107	387
1108	506
1109	257
1110	899
1111	106
1112	974
1113	221
1114	947
1115	797
1116	530
1117	696
1118	362
1119	439
1120	553
1121	862
1122	151
1123	774
1124	830
1125	869
1126	641
1127	16
1128	730
1129	992
1130	755
1131	610
1132	854
1133	210
1134	766
1135	16
1136	746
1137	115
1138	634
1139	726
1140	422
1141	249
1142	293
1143	928
1144	346
1145	220
1146	931
1147	670
1148	415
1149	842
1150	411
1151	292
1152	330
1153	222
1154	411
1155	126
1156	106
1157	588
1158	580
1159	192
1160	157
1161	895
1162	896
1163	992
1164	1
1165	348
1166	996
1167	632
1168	84
1169	601
1170	631
1171	68
1172	176
1173	303
1174	998
1175	153
1176	390
1177	195
1178	147
1179	266
1180	643
1181	872
1182	633
1183	131
1184	293
1185	287
1186	806
1187	568
1188	194
1189	149
1190	976
1191	431
1192	893
1193	893
1194	859
1195	518
1196	94
1197	489
1198	461
1199	201
1200	703
1201	824
1202	177
1203	495
1204	263
1205	9
1206	442
1207	869
1208	33
1209	936
1210	428
1211	608
1212	458
1213	503
1214	203
1215	564
1216	279
1217	852
1218	855
1219	34
1220	861
1221	328
1222	259
1223	500
1224	107
1225	169
1226	112
1227	984
1228	505
1229	349
1230	835
1231	658
1232	681
1233	8
1234	247
1235	736
1236	228
1237	843
1238	661
1239	993
1240	989
1241	181
1242	564
1243	383
1244	272
1245	647
1246	946
1247	871
1248	401
1249	953
1250	172
1251	205
1252	469
1253	45
1254	716
1255	467
1256	856
1257	477
1258	29
1259	251
1260	248
1261	343
1262	158
1263	942
1264	581
1265	506
1266	599
1267	437
1268	498
1269	24
1270	180
1271	232
1272	525
1273	860
1274	328
1275	138
1276	909
1277	324
1278	241
1279	718
1280	600
1281	293
1282	165
1283	722
1284	266
1285	780
1286	95
1287	994
1288	923
1289	578
1290	989
1291	761
1292	913
1293	291
1294	189
1295	578
1296	340
1297	953
1298	808
1299	944
1300	313
1301	213
1302	537
1303	451
1304	393
1305	647
1306	304
1307	484
1308	768
1309	411
1310	293
1311	367
1312	56
1313	195
1314	446
1315	661
1316	993
1317	470
1318	540
1319	141
1320	978
1321	705
1322	156
1323	393
1324	674
1325	765
1326	515
1327	463
1328	451
1329	735
1330	641
1331	875
1332	294
1333	370
1334	566
1335	117
1336	187
1337	155
1338	208
1339	715
1340	533
1341	777
1342	105
1343	403
1344	13
1345	256
1346	126
1347	521
1348	807
1349	104
1350	297
1351	687
1352	527
1353	707
1354	224
1355	520
1356	89
1357	481
1358	637
1359	350
1360	348
1361	947
1362	323
1363	216
1364	221
1365	282
1366	802
1367	236
1368	939
1369	293
1370	525
1371	439
1372	957
1373	79
1374	926
1375	769
1376	223
1377	376
1378	951
1379	29
1380	796
1381	635
1382	575
1383	66
1384	680
1385	972
1386	98
1387	997
1388	119
1389	883
1390	992
1391	451
1392	171
1393	561
1394	650
1395	499
1396	608
1397	307
1398	23
1399	618
1400	887
1401	619
1402	948
1403	319
1404	776
1405	209
1406	427
1407	980
1408	29
1409	834
1410	391
1411	662
1412	367
1413	305
1414	106
1415	882
1416	621
1417	532
1418	885
1419	300
1420	529
1421	750
1422	857
1423	200
1424	119
1425	636
1426	982
1427	258
1428	691
1429	555
1430	904
1431	405
1432	788
1433	5
1434	451
1435	822
1436	598
1437	468
1438	390
1439	370
1440	970
1441	658
1442	9
1443	682
1444	311
1445	2
1446	20
1447	957
1448	569
1449	389
1450	869
1451	392
1452	538
1453	860
1454	592
1455	216
1456	324
1457	941
1458	206
1459	646
1460	926
1461	650
1462	584
1463	423
1464	597
1465	744
1466	531
1467	388
1468	774
1469	414
1470	329
1471	97
1472	567
1473	100
1474	638
1475	653
1476	218
1477	566
1478	907
1479	51
1480	832
1481	562
1482	608
1483	284
1484	950
1485	888
1486	692
1487	117
1488	602
1489	503
1490	93
1491	220
1492	485
1493	957
1494	542
1495	262
1496	541
1497	610
1498	226
1499	545
1500	996
1501	698
1502	131
1503	920
1504	388
1505	633
1506	441
1507	179
1508	456
1509	809
1510	2
1511	733
1512	160
1513	678
1514	691
1515	618
1516	129
1517	138
1518	26
1519	983
1520	860
1521	216
1522	486
1523	21
1524	156
1525	406
1526	432
1527	341
1528	888
1529	354
1530	275
1531	331
1532	719
1533	617
1534	37
1535	160
1536	393
1537	391
1538	527
1539	564
1540	158
1541	510
1542	308
1543	578
1544	765
1545	668
1546	776
1547	184
1548	402
1549	646
1550	282
1551	235
1552	304
1553	93
1554	368
1555	303
1556	688
1557	915
1558	290
1559	101
1560	254
1561	44
1562	12
1563	812
1564	625
1565	465
1566	682
1567	779
1568	522
1569	77
1570	48
1571	860
1572	666
1573	32
1574	652
1575	703
1576	798
1577	779
1578	727
1579	787
1580	826
1581	120
1582	448
1583	365
1584	625
1585	778
1586	250
1587	874
1588	229
1589	196
1590	11
1591	106
1592	479
1593	516
1594	923
1595	663
1596	639
1597	56
1598	838
1599	507
1600	260
1601	205
1602	626
1603	466
1604	571
1605	635
1606	54
1607	253
1608	558
1609	5
1610	747
1611	921
1612	266
1613	757
1614	997
1615	226
1616	427
1617	841
1618	174
1619	16
1620	617
1621	517
1622	943
1623	585
1624	613
1625	873
1626	195
1627	432
1628	451
1629	557
1630	60
1631	504
1632	968
1633	995
1634	532
1635	493
1636	792
1637	759
1638	367
1639	4
1640	61
1641	882
1642	607
1643	336
1644	621
1645	898
1646	517
1647	853
1648	147
1649	94
1650	396
1651	886
1652	513
1653	801
1654	946
1655	214
1656	949
1657	886
1658	717
1659	712
1660	203
1661	858
1662	247
1663	725
1664	223
1665	336
1666	420
1667	485
1668	451
1669	727
1670	217
1671	479
1672	957
1673	822
1674	673
1675	147
1676	988
1677	908
1678	712
1679	601
1680	179
1681	298
1682	781
1683	451
1684	173
1685	944
1686	380
1687	524
1688	502
1689	85
1690	474
1691	809
1692	308
1693	843
1694	706
1695	488
1696	824
1697	639
1698	478
1699	403
1700	284
1701	693
1702	924
1703	141
1704	468
1705	509
1706	550
1707	573
1708	950
1709	458
1710	263
1711	252
1712	515
1713	360
1714	796
1715	285
1716	639
1717	407
1718	220
1719	74
1720	658
1721	148
1722	25
1723	451
1724	843
1725	252
1726	94
1727	130
1728	914
1729	397
1730	274
1731	89
1732	922
1733	231
1734	89
1735	471
1736	852
1737	46
1738	922
1739	369
1740	283
1741	689
1742	108
1743	735
1744	633
1745	400
1746	281
1747	472
1748	785
1749	354
1750	159
1751	27
1752	558
1753	443
1754	43
1755	668
1756	431
1757	510
1758	54
1759	989
1760	697
1761	206
1762	305
1763	358
1764	142
1765	224
1766	378
1767	547
1768	214
1769	745
1770	691
1771	814
1772	754
1773	535
1774	765
1775	214
1776	741
1777	201
1778	429
1779	507
1780	321
1781	381
1782	625
1783	155
1784	972
1785	279
1786	567
1787	492
1788	149
1789	714
1790	753
1791	724
1792	721
1793	980
1794	835
1795	741
1796	245
1797	235
1798	493
1799	137
1800	973
\.


--
-- TOC entry 2048 (class 0 OID 0)
-- Dependencies: 176
-- Name: accounts_accountid_seq; Type: SEQUENCE SET; Schema: main; Owner: postgres
--

SELECT pg_catalog.setval('main.accounts_accountid_seq', 1, false);


--
-- TOC entry 2035 (class 0 OID 16431)
-- Dependencies: 175
-- Data for Name: beneficiaries; Type: TABLE DATA; Schema: main; Owner: postgres
--

COPY main.beneficiaries (beneficiaryid, firstname, lastname) FROM stdin;
1	Elsie	Myrilla
2	Estell	Suanne
3	Nikki	Rosemary
4	Rivalee	Weide
5	Daryl	Fillbert
6	Elvira	Catie
7	Ada	Joli
8	Correy	Linskey
9	Alejandra	Delp
10	Doralynne	Deegan
11	Emylee	Tamar
12	Vivia	Fleeta
13	Brianna	Roche
14	Desirae	Stelle
15	Drucie	Klemperer
16	Babita	Sharl
17	Ardeen	Wandie
18	Oralee	Jerold
19	Flo	Warthman
20	Amelia	Gemini
21	Fredericka	Ummersen
22	Codie	Skurnik
23	Rubie	Lemuela
24	Jaime	Kiyoshi
25	Giustina	Allys
26	Loree	Chinua
27	Verla	Pyle
28	Angelique	Kazimir
29	Moyna	Ephrem
30	Dotty	Joseph
31	Jobi	Mott
32	Zondra	Larochelle
33	Cathie	Letsou
34	Glenda	Posner
35	Annice	Bollay
36	Lily	Olnee
37	Sandie	Tufts
38	Mahalia	Nikaniki
39	Feliza	Dahlia
40	Karena	Jefferey
41	Constance	Sinegold
42	Janeczka	Alcott
43	Karena	Krystle
44	Aurelie	Friede
45	Willetta	Ventre
46	Celene	Rossner
47	Anthia	Denis
48	Orsola	Verger
49	Atlanta	Decato
50	Paola	Thad
51	Lila	Septima
52	Brooks	Kussell
53	Adriana	Shaddock
54	Lonnie	Gerge
55	Caryl	Dowski
56	Goldie	Ortrude
57	Damaris	Woodberry
58	Shell	Therine
59	Dode	Infield
60	Ardeen	Bord
61	Jerry	Ramona
62	Vita	Sophronia
63	Daune	Randene
64	Ronna	Monaco
65	Katharina	Japeth
66	Elena	Cosenza
67	Stacey	Lalitta
68	Felice	Sallyann
69	Dulce	Sisile
70	Merrie	Pierette
71	Flo	Tomasina
72	Lauryn	Bari
73	Melisent	Edee
74	Maryellen	Raul
75	Melisent	Schwejda
76	Wileen	Hamil
77	Raquela	Hoban
78	Reeba	Hathaway
79	Christal	Bakerman
80	Corina	Hoban
81	Halette	Moseley
82	Marcelline	Shaver
83	Marnia	Chabot
84	Ruthe	Gordon
85	Shell	Hartnett
86	Kary	Merat
87	Babita	Kinnard
88	Gavrielle	Eben
89	Meghann	Rese
90	Vivia	Callista
91	Roberta	Kinnard
92	Keelia	Ailyn
93	Magdalena	Jerald
94	Pamella	Madox
95	Lizzie	Weide
96	Brianna	Berard
97	Averyl	Zeeba
98	Belva	Suk
99	Susette	Ardra
100	Grier	Tyson
101	Asia	Brunell
102	Corry	Yate
103	Jessamyn	Neils
104	Chloris	Roche
105	Dania	Bennie
106	Katleen	Hunfredo
107	Caritta	Schonfeld
108	Justinn	Vittoria
109	Jolyn	Hachmin
110	Danika	Kinnard
111	Albertina	Brady
112	Nannie	Simmonds
113	Rori	Minetta
114	Nerta	Christal
115	Carolina	McNully
116	Dorothy	Rurik
117	Ana	Read
118	Alyda	Lenny
119	Patricia	Azeria
120	Madalyn	Wesle
121	Concettina	Mozelle
122	Tomasina	Jerald
123	Belinda	Bury
124	Augustine	Lumbard
125	Bobinette	Jenness
126	Nannie	Hunfredo
127	Emma	Bendick
128	Nita	Frodi
129	Juliane	Curren
130	Flory	Bluh
131	Elena	Henebry
132	Kayla	Riva
133	Britni	Maples
134	Tonia	Lail
135	Kimberley	Eiser
136	Thalia	Ciro
137	Alie	Crudden
138	Fanny	Lattie
139	Lisette	Adalbert
140	Nananne	Judye
141	Janey	Zuzana
142	Lyssa	Lenny
143	Sam	Philipp
144	Kaia	Danby
145	Darci	Elvyn
146	Rochette	Nedrud
147	Brietta	Quinn
148	Cathyleen	Tyson
149	Mathilda	Warthman
150	Corina	Arquit
151	Flory	Rolf
152	Amara	Alwin
153	Kary	Abbot
154	Marleah	Masao
155	Di	Tengdin
156	Sibella	Nicoline
157	Dania	Sharl
158	Misha	Sekofski
159	Gilda	Yusuk
160	Sean	Baptlsta
161	Gilligan	Fitzsimmons
162	Adele	Warthman
163	Pierette	Sundin
164	Marylou	Carbo
165	Ebonee	Germann
166	Mamie	Ursulette
167	Lanae	Dorine
168	Tina	Darrell
169	Tabbatha	Craggie
170	Dione	Rebecka
171	Dorene	Lowry
172	Hannis	Lattie
173	Lexine	Bashemeth
174	Lanna	Kussell
175	Myrtice	Forrer
176	Coral	Burkle
177	Susan	Brandice
178	Cassondra	Liva
179	Rhoda	Merna
180	Jsandye	Tremayne
181	Gilda	Fulmer
182	Rochette	Norrie
183	Margarette	Kelula
184	Larine	Elisha
185	Mireielle	Ariella
186	Doralynne	Lucienne
187	Delilah	Stacy
188	Ursulina	Michella
189	Susette	Wilkinson
190	Jackie	Lymann
191	Marleah	Phyllis
192	Carmela	Jillane
193	Nataline	Lay
194	Claresta	Ax
195	Siana	Jenness
196	Ardeen	Briney
197	Kaia	Toor
198	Orsola	Kosey
199	Goldie	Morgun
200	Addia	Margarete
201	Stevana	Alice
202	Barbi	Gaal
203	Gretal	Luhe
204	Malina	Voletta
205	Gianina	Gabrielli
206	Tracey	Cristi
207	Abbie	Fennessy
208	Linzy	Olympium
209	Nerta	Luhe
210	Andeee	Azeria
211	Tiffie	Maryanne
212	Pierette	Gladstone
213	Annabela	Nelsen
214	Doralynne	Wilkinson
215	Elbertina	Allys
216	Correy	Edmund
217	Noelle	Pandolfi
218	Catrina	Fitzsimmons
219	Kylynn	Hilbert
220	Kayla	Buckler
221	Janey	Hewitt
222	Mahalia	Malanie
223	Katharina	Elephus
224	Desirae	Pandolfi
225	Shaylyn	Selway
226	Ginnie	Rossner
227	Alejandra	Ellerey
228	Moyna	Sidonius
229	Patricia	Swigart
230	Merci	Blase
231	Meg	Joachim
232	Sean	Vharat
233	Kial	Goode
234	Queenie	Roumell
235	Vanessa	Jillane
236	Imojean	Oscar
237	Annabela	Nance
238	Beatriz	Naashom
239	Nadine	Reidar
240	Mathilda	Arley
241	Nadine	Chabot
242	Joleen	Stilwell
243	Libbie	Himelman
244	Lacie	Wattenberg
245	Miquela	Schroth
246	Sybille	Alcott
247	Max	Peonir
248	Misha	Pascia
249	Lily	Billye
250	Gerrie	Chandler
251	Claresta	Primalia
252	Deloria	Blisse
253	Ruthe	LaRue
254	Peri	Kaja
255	Arabel	Ashely
256	Darci	Lareena
257	Marita	Grayce
258	Verla	Erminia
259	Amii	Marden
260	Xylina	Shuler
261	Kenna	Sinegold
262	Max	Alwin
263	Queenie	O'Carroll
264	Charissa	Kinnard
265	Vita	Trace
266	Dione	Calhoun
267	Eadie	Oster
268	Althea	Cloris
269	Corene	Freddi
270	Ermengarde	Katrine
271	Kristan	Weinreb
272	Alejandra	Thad
273	Catharine	Wenda
274	Valera	Deegan
275	Evita	Meli
276	Iseabal	Grosz
277	Max	Taam
278	Kial	Seagraves
279	Jessamyn	Niles
280	Sibella	Gregrory
281	Nannie	Salchunas
282	Jemie	Willie
283	Courtnay	Knowling
284	Jordan	Center
285	Renie	Granoff
286	Kaia	Liebermann
287	Aryn	Izaak
288	Daphne	Dominy
289	Teriann	Drus
290	Jan	Gamaliel
291	Lucy	Stephie
292	Eve	Warthman
293	Kirstin	Rurik
294	Ileana	Bashemeth
295	Glenda	Leonard
296	Margalo	Natica
297	Minne	Gilbertson
298	Debee	Cyrie
299	Emmey	Charity
300	Britte	Bebe
301	Jean	Elbertina
302	Hollie	Salvidor
303	Rosaline	Philoo
304	Nariko	Fink
305	Claresta	Decato
306	Lonnie	Dreda
307	Janey	Ivens
308	Drucie	Karl
309	Myriam	Catie
310	Clo	Jerold
311	Silvana	McNully
312	Siana	Timon
313	Leia	Chrystel
314	Imojean	Gert
315	Oona	Scammon
316	Fred	Yusuk
317	Helena	Hedve
318	Fred	Erskine
319	Philis	Erminia
320	Georgina	Faro
321	Alia	Corrine
322	Kirstin	Fax
323	Hermione	Phi
324	Zia	Idelia
325	Anthia	Ricarda
326	Raina	Sherrie
327	Livvyy	Sheedy
328	Cordi	Teryn
329	Elka	Adrienne
330	Krystle	Sadowski
331	Ira	Clie
332	Raina	Candy
333	Chloris	Schenck
334	Rayna	Braun
335	Lenna	Kaja
336	Cathyleen	Harned
337	Paulita	Bluh
338	Verla	Milson
339	Madalyn	Kunin
340	Hope	Colp
341	Priscilla	Nahum
342	Sidoney	Candy
343	Lulita	Sidonius
344	Tybie	Bandeen
345	Abbie	Isidore
346	Binny	Tiffa
347	Agnese	Alejoa
348	Tobe	Atcliffe
349	Fawne	Merna
350	Elbertina	Woodberry
351	Karly	Love
352	Cristabel	Pernick
353	Peri	Tarrant
354	Lilith	Cottle
355	Gale	Kronfeld
356	Nyssa	Wenda
357	Heddie	Zenas
358	Christian	Himelman
359	Sashenka	Jammal
360	Gilda	Kauppi
361	Cathie	Fleeta
362	Alisha	Stover
363	Hermione	Fairweather
364	Dawn	Kazimir
365	Penelopa	Lewes
366	Sindee	Hunfredo
367	Renae	Abbot
368	Petronia	Durware
369	Blinni	Dex
370	Orelia	Fulmer
371	Misha	Hertzfeld
372	Kassey	Pattin
373	Cacilie	Luhe
374	Blondelle	Emmaline
375	Aeriela	Cordi
376	Hildegaard	Lia
377	Berta	Emmaline
378	Pollyanna	Larochelle
379	Amara	Larochelle
380	Sallie	Autrey
381	Ricky	Jacinda
382	Gerianna	Nadia
383	Estell	Grayce
384	Tabbatha	Trey
385	Arlina	Celestine
386	Maisey	Roche
387	Jan	Codding
388	Kathy	Joeann
389	Luci	Fax
390	Louella	Eugenia
391	Ginnie	Kravits
392	Cristine	Colbert
393	Teriann	Yoko
394	Amii	Rosalba
395	Drucie	Quent
396	Dolli	Alva
397	Vevay	Lesley
398	Sharlene	Schwejda
399	Kary	Halsey
400	Ann-Marie	Faro
401	Thalia	Ludewig
402	Consuela	Pyle
403	Nessie	Waite
404	Pearline	Therine
405	Paola	Shields
406	Cam	Gale
407	Joelly	Sharl
408	Georgina	Aldric
409	Melanie	Ricki
410	Nariko	Zrike
411	Noelle	Miru
412	Courtnay	Maryanne
413	Alisha	Nedrud
414	Ninnetta	Corabella
415	Mahalia	Faso
416	Emylee	Nelsen
417	Clarice	Leary
418	Heida	Adlare
419	Yvonne	Wattenberg
420	Elfreda	Yoko
421	Nessie	Woodberry
422	Melina	Claudine
423	Adore	Georas
424	Danny	Harday
425	Amara	Goldina
426	Lusa	Skurnik
427	Helena	Middleton
428	Ada	Juliet
429	Noelle	Hourigan
430	Mariann	Kiyoshi
431	Susan	Carlson
432	Ayn	Malina
433	Carly	Durware
434	Maud	Cutlerr
435	Cordi	Luhe
436	Brietta	Burch
437	Almeta	Kirstin
438	Caressa	Waldron
439	Tierney	Thunell
440	Micheline	Hillel
441	Danika	Carey
442	Cacilie	McClimans
443	Gianina	Han
444	Alyssa	Emmy
445	Marguerite	Docilla
446	Kirstin	Ulphia
447	Riannon	Susannah
448	Dolli	Dorothy
449	Marti	Noelyn
450	Trudie	Maryanne
451	Ethel	Grosz
452	Nonnah	Gower
453	Kimmy	Mozelle
454	Danika	Hillel
455	Jan	Rurik
456	Constance	Madox
457	Olivette	Blake
458	Tabbatha	Elo
459	Donnie	Payson
460	Oona	Gibbeon
461	Letizia	Himelman
462	Lila	Marisa
463	Orelia	Bohlin
464	Dolli	Sherfield
465	Lizzie	Khorma
466	Sonni	Hoenack
467	Amelia	Kussell
468	Shannah	Rooney
469	Jeanna	Garlinda
470	Sharlene	Sandye
471	Wilma	Lorenz
472	Molli	Ashely
473	Dawn	Hanshaw
474	Cissiee	Madox
475	Helena	Linskey
476	Jenda	Melan
477	Liana	Anselmi
478	Dorene	Briney
479	Jessamyn	Gamaliel
480	Shauna	Elsinore
481	Alameda	Ricki
482	Ulrike	Hebner
483	Caressa	Noelyn
484	Penelopa	Sprage
485	Chere	Elbertina
486	Jorry	Thomasina
487	Philis	Japeth
488	Andree	Desai
489	Marguerite	Damarra
490	Lily	Medrek
491	Goldie	Roxanna
492	Zsa Zsa	Brenn
493	Bettine	Weitman
494	Imojean	Riva
495	Alex	Peonir
496	Jaime	Kiyoshi
497	Ana	Donoghue
498	Johna	Keily
499	Pollyanna	Cullin
500	Jere	Faust
501	Gale	Blisse
502	Helena	Stuart
503	Kellen	Saint
504	Shaylyn	Laverne
505	Cherrita	Natica
506	Vanessa	Meli
507	Ariela	Gombach
508	Dennie	Socha
509	Collen	Nadia
510	Kenna	Halsey
511	Janenna	Primalia
512	Debee	Olnee
513	Lulita	Mitzi
514	Shaine	Clara
515	Aurore	Montgomery
516	Dode	Edison
517	Linet	Smitt
518	Mariele	Ortrude
519	Meghann	Posner
520	Marika	Annice
521	Charlena	Joachim
522	Corene	Clarissa
523	Natka	Maisey
524	Dyann	Jena
525	Corly	Dalli
526	Christal	Old
527	Sophia	Kaete
528	Gretal	Bach
529	Modestia	Klotz
530	Dianemarie	Hedve
531	Frank	Colbert
532	Jinny	Agle
533	Edyth	Chandler
534	Leeanne	Cassius
535	Nyssa	Rubie
536	Alyda	Cloris
537	Cherrita	Ephrem
538	Genevra	Medrek
539	Renie	Nisbet
540	Adele	Izaak
541	Nannie	Sisile
542	Roz	Israeli
543	Cordi	Hachmin
544	Dorthy	Rad
545	Belinda	Winthorpe
546	Willetta	Leonard
547	Phedra	Si
548	Kayla	Rebecka
549	Roseline	Colbert
550	Vevay	Judye
551	Olwen	Alcott
552	Henriette	Flyn
553	Donnie	Rudolph
554	Gretal	Bonilla
555	Madeleine	Krystle
556	Yolane	Dawkins
557	Cordi	Turne
558	Cindelyn	Sadowski
559	Tiffie	Giff
560	Gabriellia	Chaing
561	Amelia	Celestine
562	Kara-Lynn	Avi
563	Roxane	Killigrew
564	Lyssa	Soneson
565	Aurelie	Lindemann
566	Rosanne	Daniele
567	Dominga	Deegan
568	Cacilie	Mintz
569	Kary	Bohlin
570	Gertrud	Peonir
571	Fayre	Ortrude
572	Elise	Pauly
573	Gwyneth	Docilla
574	Sindee	Wallis
575	Diena	Naashom
576	Hermione	Revkah
577	Sophia	Hailee
578	Kirbee	Ardeha
579	Albertina	Joseph
580	Etta	Schonfeld
581	Nikki	Kare
582	Emelina	Kauppi
583	Kittie	Winthorpe
584	Sophia	Darbie
585	Atlanta	Emmaline
586	Gisela	Lail
587	Vonny	Callista
588	Genevra	Stuart
589	Jessy	Wolfgram
590	Zsa Zsa	Gwenore
591	Wanda	Engdahl
592	Oona	Lory
593	Alexine	Anselmi
594	Emilia	Sandye
595	Nollie	Nance
596	Maisey	Pyle
597	Glynnis	Maisey
598	Almeta	Dituri
599	Benita	Skurnik
600	Deirdre	Maiah
601	Bernardine	Tatianas
602	Cecile	MacIntosh
603	Rosaline	Seagraves
604	Meriel	Isacco
605	Kaia	Olympium
606	Valeda	McNully
607	Shaylyn	Verger
608	Jessy	Plato
609	Cacilie	Anton
610	Mureil	Grosz
611	Liana	Merat
612	Dawn	Hartnett
613	Celestyna	Halsey
614	Karina	Ummersen
615	Meriel	Mauer
616	Sheelagh	Noam
617	Beatriz	Cleo
618	Shauna	Jacqui
619	Selia	Bashemeth
620	Jennica	Dielu
621	Ileana	Bonilla
622	Carolina	Alfons
623	Lonnie	MacIntosh
624	Philis	Sidonius
625	Leia	Swanhildas
626	Margalo	Therine
627	Vanessa	Belldas
628	Dominga	Oriana
629	Quintina	Vernier
630	Lusa	Alice
631	Correy	Cristi
632	Arlina	Mullane
633	Sissy	Trace
634	Beverley	Doig
635	Marti	Ummersen
636	Sharai	Winthorpe
637	Dede	Kravits
638	Jenilee	Jefferey
639	Genevra	Ellord
640	Quintina	Guildroy
641	Rochette	Dituri
642	Farrah	Karna
643	Laurene	Drisko
644	Oona	Remmer
645	Olwen	Atonsah
646	Emylee	Penelopa
647	Gilligan	Egbert
648	Marika	Zina
649	Asia	Cutlerr
650	Ricky	Parette
651	Jacenta	Zamora
652	Diena	Joni
653	Alyda	Raffo
654	Ernesta	Marlie
655	Jaclyn	Liebermann
656	Arabel	Timon
657	Kore	Masao
658	Alejandra	Ciro
659	Susan	Whittaker
660	Molli	Vastah
661	Ursulina	Tannie
662	Vanessa	Teryn
663	Kaia	Beebe
664	Phedra	Bluh
665	Lorne	Maiah
666	Rani	Latini
667	Desirae	Poppy
668	Ana	Nance
669	Ruthe	Meter
670	Aili	Stuart
671	Dione	Sammons
672	Lanae	Hamil
673	Ileana	Pearse
674	Jennica	Liebermann
675	Yolane	Grobe
676	Asia	Holbrook
677	Brana	Kirbee
678	Leia	Kalinda
679	Chrystel	Glovsky
680	Kelly	Earlie
681	Valeda	Alarise
682	Sabina	Hoban
683	Tabbatha	Forrer
684	Roxane	Kirstin
685	Genevra	Sharl
686	Fayre	Avi
687	Mady	Martsen
688	Felice	Schalles
689	Kial	Arquit
690	Devina	Zetta
691	Chickie	Xerxes
692	Nessie	Fadiman
693	Lilith	Haldas
694	Philis	Morgun
695	Lusa	Bouchard
696	Yolane	Orlene
697	Moyna	Bryna
698	Harrietta	Eckblad
699	Rosaline	Rozanna
700	Teddie	Berne
701	Marylou	Sibyls
702	Isa	Deegan
703	Agathe	Hollingsworth
704	Lila	Francene
705	Marsiella	Bluh
706	Drucie	Arley
707	Pierette	Kravits
708	Kore	Wittie
709	Mamie	Atonsah
710	Gilligan	Carbo
711	Rhoda	Leifeste
712	Diena	Jerold
713	Jorry	Zina
714	Ada	Diogenes
715	Olwen	Hedve
716	Sibella	Lunsford
717	Dione	Hillel
718	Abbie	Bashemeth
719	Ursulina	Sallyann
720	Rosene	Duwalt
721	Kristina	Pitt
722	Ingrid	Goth
723	Zia	Morrill
724	Melanie	Beebe
725	Perry	Karylin
726	Millie	Hoenack
727	Dale	Burch
728	Gaylene	Lory
729	Tersina	Jotham
730	Lorne	Peg
731	Karlee	Jary
732	Nonnah	Berl
733	Darlleen	Kravits
734	Cassandra	Carmena
735	Vivia	Anton
736	Sam	Ursulette
737	Harmonia	Marsden
738	Josephine	Penelopa
739	Joy	Lewes
740	Gilligan	Bultman
741	Beth	Himelman
742	Myriam	Seligman
743	Olwen	Ochs
744	Feliza	Curren
745	Amelia	Cressida
746	Fidelia	Alejoa
747	Arlina	Christal
748	Stacey	Bashemeth
749	Devina	Anis
750	Natka	Dorothy
751	Neila	Bebe
752	Hildegaard	Keelia
753	Aaren	Mendez
754	Gaylene	Tarrant
755	Averyl	Wyn
756	Sue	Lattie
757	Rori	Dannye
758	Consuela	Orlene
759	Julieta	Rebecka
760	Merle	Velick
761	Shaine	Dannye
762	Meg	Sinegold
763	Isa	Sinegold
764	Elsie	Natica
765	Tersina	Love
766	Maridel	Pelagias
767	Barbi	Henebry
768	Tami	Maiah
769	Heddie	Gilmour
770	Ileana	Letsou
771	Rochette	Roche
772	Ingrid	Billye
773	Alisha	Gladstone
774	Meg	Vharat
775	Camile	Fancie
776	Christy	Lorain
777	Kaia	Munn
778	Annabela	Lytton
779	Chastity	Roche
780	Doro	Georgy
781	Catrina	Morrill
782	Augustine	Vins
783	Kimmy	Chrystel
784	Sherrie	Lubin
785	Roslyn	Friede
786	Rosaline	Colp
787	Loree	Carleen
788	Rosabelle	Sibyls
789	Arlena	Newell
790	Lizzie	Ranjiv
791	Doralynne	Rona
792	Gerrie	Penelopa
793	Janenna	Dyche
794	Ilse	Kenney
795	Viviene	Lymann
796	Lulita	Wu
797	Beverley	Jalbert
798	Hermione	Magnolia
799	Ruthe	Junie
800	Dagmar	Lytton
801	Corly	Bendick
802	Tressa	Regan
803	Valli	Even
804	Belva	Rossner
805	Tobe	Regan
806	Adriana	Prober
807	Joleen	Smitt
808	Elora	Sallyann
809	Evaleen	Ackerley
810	Winifred	Jena
811	Aubrie	Fadiman
812	Kerrin	Dorcy
813	Joelly	Slifka
814	Vinita	Yam
815	Lauryn	Ralfston
816	Brietta	Rosemary
817	Coral	Autrey
818	Luci	Elo
819	Basia	Mendez
820	Kristan	Campball
821	Gilligan	Hebner
822	Emilia	Shelba
823	Agathe	Valerio
824	Melina	Vernier
825	Lanae	Cherianne
826	Sidoney	Genna
827	Glenda	Lucienne
828	Petronia	Daegal
829	Modestia	Travax
830	Mariann	Gaulin
831	Selia	Helfand
832	Ann-Marie	Radu
833	Arlena	Tamsky
834	Emylee	Colleen
835	Melodie	Rosette
836	Sarette	Odell
837	Dede	Chobot
838	Mallory	Nester
839	Nannie	Judye
840	Aurore	Euridice
841	Justinn	Giule
842	Lyssa	Christine
843	Natka	Jillane
844	Frieda	Reinke
845	Karolina	Nicoline
846	Kalina	Tomasina
847	Leia	Naor
848	Fred	Baylor
849	Liana	Maiah
850	Ezmeralda	Audly
851	Audrie	Lilybelle
852	Monika	Malina
853	Sidoney	Jenness
854	Cristine	Othilia
855	Berget	Peonir
856	Gui	Vacuva
857	Misha	Poll
858	Dorice	McGrody
859	Albertina	Sandye
860	Dania	Dorcy
861	Lenna	Odell
862	Joeann	Ries
863	Genovera	Cordi
864	Deloria	Oriana
865	Orsola	Jess
866	Willetta	Roscoe
867	Elora	Chesna
868	Genevra	Morehouse
869	Merrie	Andrel
870	Gratia	Nore
871	Collen	Kimmie
872	Monika	Fillbert
873	Karina	Francyne
874	Viki	Earlie
875	Dorothy	Bakerman
876	Dotty	Therine
877	Lanna	Brieta
878	Nicoli	Montgomery
879	Tomasina	Bandeen
880	Dale	Chauncey
881	Kara-Lynn	Curren
882	Shandie	Susannah
883	Edee	Holbrook
884	Shaine	Wareing
885	Concettina	Medrek
886	Wileen	Seessel
887	Modestia	Marcellus
888	Gilda	Halsey
889	Paola	Wilkinson
890	Rubie	Blisse
891	Debee	Moseley
892	Nelle	Karl
893	Carmencita	Harned
894	Linzy	Daniele
895	Marita	Dielu
896	Bibby	Orlene
897	Helsa	Carmena
898	Tersina	Luhe
899	Desirae	Peti
900	Albertina	Giule
901	Elsie	Klemperer
902	Janey	Prober
903	Larine	Rustice
904	Wendi	Sherfield
905	Donetta	Letsou
906	Fawne	Whittaker
907	Sashenka	Dulciana
908	Misha	Kare
909	Leona	Sophronia
910	Ebonee	Lutero
911	Myriam	Mozelle
912	Wanda	Swigart
913	Luci	Seligman
914	Kathi	Bettine
915	Veda	Burkle
916	Krystle	Sophronia
917	Heddie	Sawtelle
918	Devina	Tremayne
919	Cherilyn	Rozanna
920	Blondelle	Shama
921	Inga	Seumas
922	Adele	Pozzy
923	Maisey	Elo
924	Margette	Anastatius
925	Shaine	Hanleigh
926	Janis	Creamer
927	Romona	Edvard
928	Philis	Natica
929	Gilligan	Faso
930	Latisha	Gemini
931	Cordi	Wadell
932	Gianina	Rad
933	Dania	Delp
934	Nannie	Elephus
935	Ira	Khorma
936	Winny	Cutlerr
937	Cristabel	Pascia
938	Laure	Tyson
939	Siana	Mayeda
940	Regina	Goldina
941	Clo	Muriel
942	Malina	Neils
943	Roxane	Jehu
944	Marika	Sherfield
945	Ottilie	Payson
946	Glynnis	Idelia
947	Marti	Jerold
948	Farrah	Valerio
949	Dione	Jerald
950	Dorene	Lanita
951	Wileen	Yerkovich
952	Marylou	Wilona
953	Jorry	Fry
954	Lynde	Yoko
955	Emma	Martsen
956	Viki	McClimans
957	Taffy	Kimmie
958	Belva	Blisse
959	Pearline	Dearborn
960	Eve	Hermes
961	Max	Ruvolo
962	Suzette	Taam
963	Catharine	Tryck
964	Alie	Darrell
965	Adelle	Syd
966	Lusa	Bohlin
967	Larine	Tamar
968	Maye	Merell
969	Goldie	Louanna
970	Tera	Deegan
971	Dianemarie	Cutlerr
972	Averyl	Lasley
973	Caressa	Lowry
974	Charmaine	Audly
975	Mildrid	Audly
976	Lilith	Evvie
977	Aubrie	Herrera
978	Andeee	Hamil
979	Carolina	Aaberg
980	Xylina	Graig
981	Gale	Yam
982	Carlie	Taam
983	Rori	Sheng
984	Carilyn	Roxanna
985	Dari	Kaja
986	Heddie	Peg
987	Dulcinea	Hertzfeld
988	Winny	Kevon
989	Fawne	Christine
990	Nessie	Capello
991	Konstance	Cadmar
992	Damaris	Lowry
993	Di	Judye
994	Misha	Hoban
995	Meghann	Brotherson
996	Asia	Keelia
997	Devina	Jorgan
998	Xylina	Pond
999	Misha	Latini
1000	Suzette	Papageno
\.


--
-- TOC entry 2049 (class 0 OID 0)
-- Dependencies: 174
-- Name: beneficiaries_beneficiaryid_seq; Type: SEQUENCE SET; Schema: main; Owner: postgres
--

SELECT pg_catalog.setval('main.beneficiaries_beneficiaryid_seq', 1, false);


--
-- TOC entry 2039 (class 0 OID 16453)
-- Dependencies: 179
-- Data for Name: transactions; Type: TABLE DATA; Schema: main; Owner: postgres
--

COPY main.transactions (transactionid, accountid, amount, type, trans_date) FROM stdin;
1	1395	41.20	withdrawal	2023-10-24
2	164	59.80	deposit	2023-12-03
3	996	27.30	withdrawal	2023-12-01
4	292	413.10	withdrawal	2023-09-26
5	972	457.20	deposit	2023-07-11
6	1068	67.30	withdrawal	2023-03-20
7	649	109.20	deposit	2023-09-06
8	80	318.80	withdrawal	2024-05-24
9	18	411.50	deposit	2023-01-29
10	24	12.40	withdrawal	2024-05-24
11	1435	411.80	withdrawal	2024-03-12
12	1280	189.00	deposit	2023-03-07
13	1764	441.30	deposit	2023-11-18
14	1558	316.60	deposit	2023-12-19
15	1633	435.40	withdrawal	2024-01-20
16	1140	254.50	withdrawal	2024-01-25
17	716	223.70	withdrawal	2023-07-27
18	1716	391.30	deposit	2023-12-07
19	991	185.20	withdrawal	2023-09-02
20	1621	282.50	deposit	2024-02-21
21	166	361.70	withdrawal	2024-01-21
22	1186	85.20	withdrawal	2024-03-08
23	1765	461.10	deposit	2024-01-29
24	581	257.80	withdrawal	2023-11-20
25	227	135.80	withdrawal	2024-05-09
26	1104	457.60	deposit	2023-08-18
27	25	107.00	deposit	2023-11-12
28	352	207.70	withdrawal	2023-03-11
29	1763	462.70	withdrawal	2023-02-25
30	431	174.60	withdrawal	2023-06-07
31	255	205.50	deposit	2023-03-16
32	1440	358.10	deposit	2023-06-05
33	407	152.50	withdrawal	2024-02-16
34	1526	140.40	deposit	2023-08-17
35	1738	136.90	deposit	2024-04-28
36	1716	205.00	deposit	2023-05-22
37	941	174.80	withdrawal	2023-03-13
38	1639	322.20	deposit	2023-02-10
39	404	415.90	withdrawal	2023-09-03
40	1564	462.20	withdrawal	2024-03-30
41	1432	283.40	deposit	2024-01-27
42	464	200.70	withdrawal	2024-02-10
43	1279	488.60	withdrawal	2023-12-14
44	1664	227.60	withdrawal	2023-04-07
45	303	364.00	withdrawal	2024-03-10
46	659	249.50	deposit	2023-07-25
47	319	329.00	deposit	2023-02-23
48	1584	63.60	deposit	2023-07-15
49	1760	329.70	deposit	2023-07-11
50	626	326.80	withdrawal	2024-04-22
51	529	163.50	deposit	2023-10-03
52	278	163.90	deposit	2024-01-31
53	180	104.00	withdrawal	2023-02-19
54	1570	88.80	deposit	2024-01-06
55	1772	299.50	deposit	2024-04-04
56	738	470.80	withdrawal	2023-07-28
57	809	408.30	withdrawal	2023-12-04
58	1186	347.50	deposit	2023-10-19
59	6	387.60	deposit	2023-11-15
60	1721	142.60	deposit	2023-09-04
61	438	114.20	withdrawal	2023-08-24
62	1423	55.80	withdrawal	2023-11-27
63	994	175.00	withdrawal	2024-03-10
64	263	407.50	deposit	2024-02-24
65	1330	286.70	deposit	2023-07-03
66	152	155.90	deposit	2023-12-10
67	1750	285.30	withdrawal	2023-07-08
68	1625	302.20	deposit	2023-06-28
69	1643	283.40	deposit	2024-02-23
70	1665	8.00	deposit	2023-01-20
71	1635	201.80	withdrawal	2023-03-18
72	1236	249.70	withdrawal	2023-12-13
73	1370	74.60	deposit	2023-01-06
74	1788	292.80	deposit	2023-09-15
75	222	396.00	deposit	2023-06-19
76	2	318.80	deposit	2023-01-31
77	883	159.20	withdrawal	2023-02-07
78	409	54.00	withdrawal	2024-03-08
79	435	182.70	withdrawal	2024-01-22
80	1056	367.40	deposit	2024-05-25
81	572	294.10	deposit	2023-03-23
82	99	47.30	withdrawal	2023-04-15
83	728	305.90	withdrawal	2023-06-08
84	375	305.10	withdrawal	2024-03-21
85	221	349.40	deposit	2024-05-03
86	1602	369.10	deposit	2023-10-01
87	1356	369.50	deposit	2023-12-19
88	44	91.10	withdrawal	2023-05-01
89	1646	435.50	deposit	2023-09-29
90	391	445.50	withdrawal	2024-05-04
91	155	218.80	deposit	2023-02-06
92	1486	141.20	deposit	2024-03-22
93	630	127.40	deposit	2024-05-16
94	863	81.00	withdrawal	2023-02-25
95	421	142.80	deposit	2024-04-11
96	393	144.90	withdrawal	2024-04-28
97	561	478.60	deposit	2023-01-04
98	527	55.60	deposit	2023-03-12
99	1524	377.80	deposit	2023-11-22
100	412	174.10	deposit	2024-05-28
101	1373	463.30	deposit	2023-11-17
102	932	117.40	deposit	2023-12-17
103	131	217.50	withdrawal	2023-07-27
104	349	431.20	deposit	2023-05-03
105	467	91.30	deposit	2023-01-01
106	401	70.40	deposit	2023-06-12
107	89	361.20	deposit	2024-02-04
108	1091	237.90	withdrawal	2023-06-15
109	129	122.20	deposit	2023-11-08
110	525	284.30	withdrawal	2023-08-26
111	1475	394.70	deposit	2023-10-12
112	1089	419.70	deposit	2023-01-11
113	432	363.80	withdrawal	2023-11-02
114	577	245.60	withdrawal	2024-04-04
115	217	140.00	withdrawal	2023-05-10
116	927	145.80	withdrawal	2023-09-29
117	1438	374.10	deposit	2023-02-24
118	727	399.50	deposit	2023-04-30
119	471	424.40	deposit	2023-06-22
120	803	247.50	deposit	2023-11-02
121	600	134.20	withdrawal	2024-02-13
122	1332	233.60	deposit	2023-01-10
123	1245	15.20	deposit	2023-09-23
124	37	235.60	withdrawal	2023-05-22
125	1732	20.70	withdrawal	2024-02-08
126	216	425.70	withdrawal	2023-08-30
127	611	493.70	withdrawal	2024-04-13
128	1613	297.50	withdrawal	2023-12-18
129	257	241.40	withdrawal	2023-10-29
130	1192	497.30	withdrawal	2024-04-13
131	553	164.00	deposit	2023-12-07
132	1592	207.90	withdrawal	2024-02-13
133	1634	378.50	withdrawal	2023-08-08
134	1696	230.40	deposit	2023-10-15
135	1312	347.90	deposit	2023-09-10
136	1081	68.20	withdrawal	2023-10-15
137	223	228.00	withdrawal	2024-04-30
138	1410	422.90	deposit	2023-07-12
139	1046	417.10	withdrawal	2024-02-17
140	850	364.90	deposit	2023-05-31
141	294	148.80	deposit	2023-10-06
142	330	371.90	deposit	2023-07-18
143	926	38.10	withdrawal	2024-05-28
144	338	313.90	withdrawal	2024-03-06
145	555	197.80	deposit	2024-04-26
146	307	297.00	deposit	2024-03-25
147	976	404.10	deposit	2023-08-22
148	1778	91.70	deposit	2023-04-28
149	981	385.80	withdrawal	2023-04-28
150	156	356.70	deposit	2023-03-29
151	1443	158.30	deposit	2024-01-24
152	1241	88.10	deposit	2023-09-10
153	1677	368.60	withdrawal	2023-01-04
154	1667	256.40	deposit	2023-07-09
155	1182	124.30	withdrawal	2023-12-24
156	919	118.10	withdrawal	2023-12-01
157	1132	170.40	withdrawal	2023-01-02
158	1157	62.70	deposit	2023-11-16
159	100	204.20	deposit	2023-11-26
160	978	339.60	withdrawal	2024-02-11
161	1593	286.30	withdrawal	2023-08-15
162	1340	95.90	deposit	2024-03-14
163	813	448.40	withdrawal	2023-08-12
164	1630	255.90	deposit	2023-01-14
165	80	283.80	withdrawal	2023-06-29
166	581	93.50	deposit	2023-06-01
167	1799	238.60	withdrawal	2023-02-10
168	848	380.70	deposit	2023-01-01
169	1704	11.80	withdrawal	2023-11-06
170	189	389.10	deposit	2024-01-05
171	493	416.80	withdrawal	2024-05-31
172	1453	325.90	withdrawal	2023-12-19
173	1300	270.80	deposit	2024-05-05
174	694	7.30	withdrawal	2024-04-06
175	1720	383.50	withdrawal	2024-05-31
176	1214	493.10	withdrawal	2023-05-02
177	655	252.10	deposit	2023-11-06
178	810	270.50	deposit	2024-02-13
179	1719	118.00	withdrawal	2024-02-28
180	1061	221.20	deposit	2023-01-20
181	1494	353.10	withdrawal	2023-06-01
182	598	374.70	withdrawal	2023-06-02
183	1323	26.00	withdrawal	2023-09-17
184	509	52.10	deposit	2024-03-15
185	225	89.40	withdrawal	2023-02-13
186	513	236.60	withdrawal	2024-04-23
187	880	61.10	deposit	2023-09-28
188	1631	138.70	withdrawal	2023-04-24
189	520	474.40	withdrawal	2023-08-16
190	1699	368.60	deposit	2023-12-17
191	867	256.80	deposit	2023-09-17
192	1642	239.80	deposit	2024-04-14
193	593	400.20	withdrawal	2023-10-06
194	405	14.20	withdrawal	2024-04-21
195	1637	408.60	withdrawal	2023-08-02
196	518	221.30	deposit	2023-11-01
197	816	228.30	deposit	2023-04-05
198	488	13.40	deposit	2023-03-01
199	632	162.70	deposit	2023-04-25
200	265	333.20	withdrawal	2023-05-14
201	1786	213.00	deposit	2024-04-17
202	1670	328.20	deposit	2024-02-25
203	1696	199.20	deposit	2023-08-05
204	510	370.10	deposit	2023-11-23
205	1401	192.20	withdrawal	2024-03-07
206	1129	495.80	withdrawal	2024-05-17
207	290	172.60	withdrawal	2024-05-20
208	1106	322.60	deposit	2024-01-17
209	974	179.80	withdrawal	2024-02-10
210	1443	210.30	deposit	2023-03-10
211	1723	465.30	deposit	2024-02-17
212	303	201.20	deposit	2023-04-27
213	391	125.80	withdrawal	2023-04-03
214	1323	398.60	withdrawal	2023-02-19
215	1318	483.60	deposit	2023-11-16
216	1149	283.80	deposit	2024-04-19
217	238	360.00	deposit	2023-07-24
218	172	166.80	deposit	2023-07-06
219	33	235.40	deposit	2023-12-12
220	418	362.60	deposit	2024-04-30
221	690	50.30	deposit	2024-01-25
222	190	184.20	deposit	2023-12-25
223	1379	442.80	deposit	2023-02-14
224	1487	91.70	deposit	2023-01-13
225	660	293.80	deposit	2023-03-10
226	361	128.50	deposit	2023-12-08
227	453	176.90	deposit	2023-02-05
228	961	265.50	deposit	2023-03-06
229	40	269.50	withdrawal	2023-10-21
230	984	69.80	withdrawal	2023-07-01
231	339	336.40	withdrawal	2023-10-20
232	992	425.00	deposit	2023-07-24
233	928	174.40	deposit	2024-01-20
234	1608	378.70	withdrawal	2023-06-14
235	983	285.80	withdrawal	2023-02-17
236	156	189.30	withdrawal	2023-10-09
237	566	268.90	deposit	2024-01-25
238	1688	473.20	withdrawal	2024-01-13
239	714	26.00	deposit	2023-12-06
240	1612	307.90	deposit	2023-11-24
241	42	208.40	withdrawal	2023-04-25
242	1609	72.20	withdrawal	2023-04-23
243	452	128.50	deposit	2023-04-07
244	1740	250.40	deposit	2024-02-26
245	1482	288.50	deposit	2024-04-05
246	1694	467.80	deposit	2024-03-02
247	895	282.00	deposit	2024-01-07
248	701	138.80	withdrawal	2023-10-10
249	518	79.20	deposit	2023-04-20
250	1094	386.10	deposit	2023-02-20
251	795	55.10	withdrawal	2023-05-20
252	520	500.80	withdrawal	2023-02-08
253	1391	244.30	withdrawal	2023-02-08
254	1445	47.40	withdrawal	2023-08-31
255	1324	241.00	deposit	2023-04-17
256	1598	211.80	deposit	2023-04-10
257	1204	178.00	withdrawal	2023-12-28
258	598	286.80	withdrawal	2023-01-12
259	1299	77.80	deposit	2024-03-13
260	778	491.20	withdrawal	2024-04-13
261	1412	443.70	deposit	2024-01-29
262	137	302.50	withdrawal	2023-08-01
263	841	447.10	deposit	2023-05-25
264	727	221.40	withdrawal	2023-01-16
265	1585	15.10	withdrawal	2023-10-11
266	11	81.60	deposit	2023-01-29
267	436	108.10	withdrawal	2024-05-09
268	398	296.10	deposit	2023-04-19
269	1709	353.40	withdrawal	2023-10-14
270	1328	344.90	deposit	2023-03-13
271	788	432.60	deposit	2023-10-27
272	845	359.20	deposit	2023-10-29
273	1489	379.50	withdrawal	2023-07-22
274	691	361.40	deposit	2023-07-13
275	169	141.10	deposit	2023-01-03
276	906	152.40	withdrawal	2024-05-08
277	204	46.60	withdrawal	2023-02-11
278	667	96.70	deposit	2023-12-09
279	1114	59.70	withdrawal	2023-11-16
280	1482	447.80	withdrawal	2023-02-28
281	219	223.10	withdrawal	2023-09-19
282	905	460.80	withdrawal	2023-10-30
283	1356	41.20	deposit	2024-01-04
284	1349	27.40	withdrawal	2023-11-07
285	1070	369.70	withdrawal	2023-04-30
286	1785	454.00	withdrawal	2023-05-26
287	1372	359.70	withdrawal	2023-05-21
288	1495	443.80	deposit	2023-10-03
289	514	226.50	withdrawal	2024-02-24
290	860	80.90	withdrawal	2024-05-08
291	62	363.80	deposit	2023-08-04
292	772	256.20	deposit	2023-03-08
293	678	225.50	withdrawal	2024-01-05
294	146	395.30	deposit	2023-07-04
295	935	23.40	withdrawal	2023-09-12
296	658	173.70	withdrawal	2023-10-16
297	1480	71.30	deposit	2023-05-12
298	1030	20.90	withdrawal	2023-04-01
299	1751	255.40	deposit	2024-02-13
300	476	454.40	withdrawal	2024-02-22
301	324	431.00	deposit	2024-05-27
302	1547	202.90	deposit	2024-01-24
303	799	17.50	withdrawal	2023-04-25
304	1617	484.60	withdrawal	2023-09-01
305	64	84.40	deposit	2024-05-03
306	524	74.50	deposit	2023-09-05
307	573	471.70	withdrawal	2023-10-16
308	545	68.40	deposit	2024-03-18
309	554	400.70	deposit	2023-11-07
310	547	125.00	withdrawal	2024-03-01
311	797	420.70	withdrawal	2024-02-25
312	75	270.10	withdrawal	2024-02-10
313	537	363.00	deposit	2023-02-03
314	947	375.40	deposit	2023-08-06
315	1218	304.90	deposit	2023-07-21
316	924	271.30	withdrawal	2023-10-21
317	318	312.00	withdrawal	2023-05-26
318	1227	94.10	deposit	2024-05-26
319	411	344.90	withdrawal	2023-03-23
320	154	324.50	withdrawal	2024-02-01
321	6	234.30	deposit	2024-05-13
322	250	281.00	deposit	2023-10-08
323	1008	89.60	deposit	2023-03-28
324	1275	489.60	withdrawal	2023-05-21
325	1746	138.80	deposit	2024-01-02
326	931	282.90	withdrawal	2024-04-28
327	39	44.60	deposit	2023-09-12
328	899	396.20	withdrawal	2023-12-27
329	167	209.40	withdrawal	2024-03-18
330	632	426.60	withdrawal	2023-09-22
331	223	170.30	withdrawal	2023-09-15
332	872	318.00	withdrawal	2023-03-09
333	1513	488.40	deposit	2023-06-03
334	146	176.20	deposit	2024-02-10
335	506	451.60	deposit	2023-07-03
336	677	334.90	withdrawal	2023-03-07
337	1092	156.40	withdrawal	2024-05-11
338	787	78.10	withdrawal	2023-09-25
339	1093	177.90	withdrawal	2023-10-21
340	1096	83.60	deposit	2023-09-18
341	1015	72.10	deposit	2024-05-28
342	1610	373.00	withdrawal	2023-01-18
343	1048	114.60	deposit	2023-06-24
344	1082	134.60	withdrawal	2023-12-07
345	767	306.00	deposit	2023-09-04
346	95	255.80	withdrawal	2023-05-18
347	237	223.00	withdrawal	2023-08-18
348	1702	212.50	withdrawal	2023-01-02
349	1013	449.50	deposit	2023-05-18
350	1366	467.90	withdrawal	2023-07-23
351	1	11.50	deposit	2023-08-09
352	1390	269.60	deposit	2024-03-03
353	566	242.30	withdrawal	2023-06-29
354	1029	80.40	deposit	2023-06-02
355	176	282.30	withdrawal	2023-04-24
356	739	170.10	deposit	2023-03-22
357	1124	316.30	withdrawal	2023-05-16
358	1187	123.90	withdrawal	2023-10-08
359	289	370.50	withdrawal	2023-08-30
360	1719	249.90	deposit	2023-12-14
361	367	347.50	deposit	2023-01-09
362	1509	361.70	deposit	2024-02-22
363	509	84.90	withdrawal	2023-02-26
364	1020	452.10	withdrawal	2023-03-06
365	1587	107.80	deposit	2023-01-26
366	287	349.20	withdrawal	2023-09-22
367	1056	267.50	withdrawal	2023-09-11
368	1288	353.30	withdrawal	2023-02-12
369	5	471.20	withdrawal	2024-01-25
370	946	143.00	withdrawal	2023-08-25
371	355	240.30	deposit	2023-12-08
372	597	137.00	withdrawal	2023-07-23
373	1517	41.20	deposit	2023-06-14
374	815	452.90	deposit	2023-03-01
375	803	242.50	deposit	2023-08-10
376	819	142.00	deposit	2023-03-01
377	510	138.10	deposit	2023-12-20
378	700	269.00	withdrawal	2024-01-26
379	56	16.30	withdrawal	2023-10-26
380	80	369.90	withdrawal	2024-05-07
381	624	360.30	deposit	2024-01-28
382	694	363.90	withdrawal	2024-05-11
383	610	453.00	withdrawal	2024-01-06
384	328	260.40	deposit	2023-12-24
385	910	476.10	withdrawal	2023-03-06
386	787	450.60	deposit	2024-02-25
387	1258	238.70	withdrawal	2023-11-23
388	1181	248.80	deposit	2024-05-11
389	434	399.10	withdrawal	2023-09-25
390	20	27.00	withdrawal	2023-07-16
391	247	456.00	withdrawal	2023-06-05
392	564	283.80	withdrawal	2023-03-29
393	21	312.60	withdrawal	2023-06-08
394	1281	172.00	withdrawal	2024-04-07
395	759	449.10	deposit	2024-01-05
396	418	304.50	withdrawal	2023-08-24
397	184	441.70	withdrawal	2023-03-01
398	1496	345.10	deposit	2023-12-02
399	1498	74.30	withdrawal	2023-11-03
400	1493	239.10	withdrawal	2023-12-26
401	1295	199.30	withdrawal	2024-02-08
402	1602	245.00	deposit	2023-09-13
403	76	335.30	deposit	2023-10-04
404	904	99.70	deposit	2023-01-01
405	1736	31.10	deposit	2024-04-07
406	859	389.70	withdrawal	2024-05-04
407	212	379.40	deposit	2023-05-19
408	1237	126.00	deposit	2024-05-25
409	640	264.00	deposit	2023-12-21
410	1054	359.00	deposit	2023-11-15
411	1327	215.00	withdrawal	2023-07-27
412	70	346.80	deposit	2023-08-11
413	1697	463.90	deposit	2024-04-24
414	998	164.90	deposit	2023-01-18
415	1415	100.10	deposit	2023-05-03
416	657	267.50	withdrawal	2023-04-17
417	838	242.30	deposit	2023-05-17
418	917	321.20	withdrawal	2023-08-06
419	437	148.50	deposit	2023-12-14
420	10	382.90	deposit	2023-07-04
421	1189	383.00	withdrawal	2024-01-12
422	482	69.80	deposit	2023-10-13
423	1276	110.90	withdrawal	2023-05-05
424	159	428.40	withdrawal	2023-04-11
425	1713	278.50	withdrawal	2023-02-08
426	1791	325.60	withdrawal	2023-05-25
427	333	55.40	deposit	2023-12-14
428	819	306.10	withdrawal	2024-02-22
429	1079	308.30	withdrawal	2023-06-03
430	736	110.40	withdrawal	2024-03-03
431	1037	312.00	deposit	2024-02-02
432	302	342.60	deposit	2023-09-15
433	86	325.50	withdrawal	2023-03-10
434	1025	197.70	deposit	2024-05-22
435	914	486.40	withdrawal	2024-02-02
436	1211	282.90	deposit	2024-01-10
437	258	432.50	withdrawal	2023-04-15
438	1202	101.10	deposit	2024-01-04
439	1530	141.10	withdrawal	2023-07-23
440	762	37.30	withdrawal	2024-05-15
441	833	346.30	withdrawal	2023-03-26
442	733	437.30	withdrawal	2023-08-14
443	1702	289.40	withdrawal	2024-02-20
444	272	6.30	withdrawal	2023-06-17
445	1756	139.20	deposit	2024-05-04
446	95	360.00	withdrawal	2023-08-29
447	1026	170.80	deposit	2023-11-08
448	868	157.20	withdrawal	2023-08-24
449	1664	373.20	deposit	2023-04-28
450	1642	282.90	deposit	2023-07-13
451	226	479.50	deposit	2024-05-06
452	984	238.30	deposit	2024-01-07
453	1754	190.40	withdrawal	2023-10-23
454	345	410.80	withdrawal	2024-02-17
455	10	332.90	deposit	2024-01-24
456	1120	235.90	withdrawal	2024-03-21
457	1609	173.00	deposit	2023-04-27
458	458	484.70	withdrawal	2023-07-03
459	1044	348.10	deposit	2023-10-05
460	834	337.20	withdrawal	2023-06-13
461	440	347.00	deposit	2023-04-27
462	628	73.30	withdrawal	2023-07-27
463	764	148.30	withdrawal	2023-05-03
464	1471	114.90	deposit	2023-01-12
465	860	148.00	deposit	2023-08-23
466	1322	114.30	deposit	2023-12-14
467	299	494.00	withdrawal	2024-04-07
468	1637	413.60	deposit	2023-05-01
469	745	67.60	withdrawal	2024-04-16
470	686	488.60	deposit	2023-02-07
471	1790	324.70	withdrawal	2023-04-08
472	811	258.40	withdrawal	2023-02-07
473	677	449.80	deposit	2024-03-09
474	514	381.40	deposit	2023-04-21
475	1112	475.60	withdrawal	2024-03-09
476	159	331.30	deposit	2023-02-06
477	1070	200.80	withdrawal	2023-05-30
478	329	257.40	withdrawal	2023-10-15
479	982	232.90	deposit	2023-04-27
480	647	164.10	withdrawal	2024-04-27
481	619	485.90	deposit	2023-01-20
482	1488	122.30	deposit	2023-05-22
483	489	102.60	deposit	2023-09-09
484	539	471.30	deposit	2023-06-21
485	684	297.90	withdrawal	2023-09-13
486	881	55.30	deposit	2023-01-12
487	504	51.30	deposit	2023-04-16
488	1262	179.50	withdrawal	2024-03-06
489	736	240.90	deposit	2023-07-16
490	572	465.50	deposit	2023-05-08
491	758	118.20	withdrawal	2023-04-22
492	1451	263.70	deposit	2024-05-21
493	1217	188.70	withdrawal	2023-11-20
494	1383	408.70	deposit	2024-02-13
495	1466	377.80	withdrawal	2024-01-29
496	354	323.40	withdrawal	2023-03-15
497	760	46.50	deposit	2023-06-20
498	1025	214.00	deposit	2023-02-27
499	968	88.20	withdrawal	2023-07-19
500	1102	315.10	withdrawal	2023-02-07
501	484	22.60	deposit	2023-08-23
502	1226	241.40	deposit	2024-01-16
503	152	12.90	withdrawal	2023-07-28
504	935	192.10	withdrawal	2023-12-18
505	1416	284.20	withdrawal	2023-05-26
506	382	85.80	deposit	2023-05-20
507	745	57.30	deposit	2023-05-14
508	1475	55.30	deposit	2023-10-16
509	807	109.10	withdrawal	2023-05-02
510	480	262.60	deposit	2023-11-22
511	755	66.60	withdrawal	2024-02-06
512	1737	249.00	withdrawal	2023-03-08
513	1539	184.40	withdrawal	2023-12-04
514	1153	298.80	withdrawal	2023-05-23
515	401	208.50	withdrawal	2023-03-19
516	1009	474.60	deposit	2023-06-22
517	1626	467.10	deposit	2023-03-13
518	469	362.40	withdrawal	2023-12-07
519	991	242.70	withdrawal	2023-01-28
520	1544	341.10	withdrawal	2023-08-19
521	687	200.00	withdrawal	2024-02-13
522	1291	199.90	deposit	2023-09-28
523	177	431.80	withdrawal	2023-07-30
524	1100	78.90	deposit	2023-06-07
525	1375	245.90	withdrawal	2023-11-01
526	1065	464.30	withdrawal	2024-02-16
527	1426	142.40	withdrawal	2024-02-10
528	465	31.80	deposit	2023-01-03
529	15	286.40	withdrawal	2023-07-29
530	82	222.30	deposit	2024-03-03
531	536	373.70	deposit	2024-03-21
532	1013	133.80	withdrawal	2024-02-07
533	214	165.60	withdrawal	2023-12-11
534	1483	98.90	deposit	2023-09-08
535	292	70.20	withdrawal	2024-03-14
536	1798	420.50	deposit	2024-03-21
537	1257	197.50	withdrawal	2024-03-22
538	544	302.50	deposit	2023-11-16
539	222	179.10	deposit	2024-01-04
540	1024	82.80	deposit	2023-11-17
541	1542	434.70	deposit	2024-05-11
542	1339	54.80	withdrawal	2024-03-01
543	760	200.90	deposit	2023-03-18
544	1250	382.70	deposit	2023-02-15
545	1695	416.90	deposit	2023-05-24
546	1532	344.90	withdrawal	2024-01-14
547	1512	424.20	deposit	2024-01-15
548	710	15.10	deposit	2023-07-10
549	1795	42.20	withdrawal	2023-09-21
550	1622	97.10	withdrawal	2023-09-28
551	650	173.30	withdrawal	2023-11-14
552	520	345.80	withdrawal	2024-02-05
553	501	88.80	withdrawal	2023-12-11
554	113	178.20	withdrawal	2024-03-06
555	1755	283.20	deposit	2023-10-27
556	504	326.90	withdrawal	2024-01-06
557	1313	283.30	deposit	2024-01-04
558	728	99.50	withdrawal	2023-01-17
559	838	307.60	deposit	2023-08-06
560	301	315.60	withdrawal	2023-03-05
561	176	12.00	withdrawal	2024-01-10
562	173	464.10	deposit	2023-01-19
563	506	284.50	withdrawal	2023-11-12
564	1556	325.40	deposit	2023-04-29
565	347	346.10	deposit	2023-09-15
566	232	165.50	withdrawal	2024-01-22
567	491	9.90	withdrawal	2023-06-26
568	1487	199.80	withdrawal	2023-03-02
569	684	262.30	withdrawal	2023-11-21
570	1070	466.50	deposit	2023-03-10
571	174	182.70	withdrawal	2023-08-10
572	1222	259.60	deposit	2023-08-22
573	292	443.90	deposit	2023-03-06
689	1653	61.40	withdrawal	2023-11-15
574	656	123.80	withdrawal	2024-01-12
575	590	346.20	deposit	2023-05-17
576	689	345.90	deposit	2024-04-07
577	1644	371.80	deposit	2023-12-01
578	647	245.20	deposit	2023-07-23
579	1310	385.40	withdrawal	2023-07-29
580	43	386.60	deposit	2023-11-03
581	74	319.90	withdrawal	2024-03-03
582	263	169.40	withdrawal	2024-05-25
583	779	425.00	deposit	2023-05-07
584	446	164.30	deposit	2023-11-22
585	834	426.00	deposit	2023-11-24
586	1671	74.70	withdrawal	2023-03-21
587	871	23.20	withdrawal	2024-04-08
588	1325	218.90	withdrawal	2023-12-23
589	75	45.20	deposit	2023-10-17
590	1572	159.60	withdrawal	2023-06-12
591	883	315.30	withdrawal	2023-06-03
592	983	95.80	deposit	2023-10-02
593	266	162.70	deposit	2024-04-28
594	778	275.90	withdrawal	2023-07-02
595	501	231.50	withdrawal	2023-09-11
596	1748	323.70	withdrawal	2024-05-14
597	1567	363.80	withdrawal	2023-03-25
598	1217	273.70	withdrawal	2023-04-24
599	694	196.80	deposit	2024-03-24
600	286	49.30	deposit	2023-09-21
601	968	61.40	withdrawal	2023-02-22
602	1039	13.80	withdrawal	2023-02-13
603	1630	187.80	deposit	2023-04-12
604	1219	116.60	deposit	2023-11-30
605	32	237.00	withdrawal	2023-06-01
606	1247	403.30	withdrawal	2023-10-07
607	1800	223.60	deposit	2024-04-29
608	682	295.50	withdrawal	2023-12-01
609	209	491.70	withdrawal	2023-11-30
610	372	425.60	deposit	2024-02-02
611	349	100.80	withdrawal	2023-12-09
612	1121	214.40	deposit	2024-02-21
613	226	227.10	deposit	2023-06-08
614	1256	191.60	withdrawal	2023-01-20
615	667	347.30	deposit	2023-06-10
616	884	297.30	deposit	2023-04-22
617	1615	39.30	deposit	2023-07-02
618	23	270.10	withdrawal	2023-02-04
619	868	142.80	withdrawal	2023-10-29
620	1654	215.00	deposit	2023-02-09
621	1701	292.00	withdrawal	2024-04-18
622	505	444.10	withdrawal	2023-08-27
623	1166	374.50	withdrawal	2024-04-17
624	1296	157.80	withdrawal	2023-02-01
625	1208	13.10	withdrawal	2024-02-01
626	444	177.00	withdrawal	2024-05-24
627	327	300.20	deposit	2023-07-11
628	214	478.50	withdrawal	2023-03-13
629	775	161.50	withdrawal	2023-02-26
630	653	280.40	withdrawal	2023-04-04
631	846	473.90	withdrawal	2024-03-25
632	1521	7.40	deposit	2023-09-18
633	908	88.40	deposit	2024-04-25
634	666	407.00	withdrawal	2023-06-03
635	1588	153.50	withdrawal	2023-03-12
636	550	214.50	deposit	2023-05-31
637	500	188.60	deposit	2023-09-28
638	698	24.90	withdrawal	2023-04-21
639	58	177.20	withdrawal	2023-11-25
640	1466	484.20	deposit	2023-04-24
641	765	24.20	withdrawal	2024-03-24
642	1617	458.80	deposit	2023-10-24
643	1037	172.10	withdrawal	2023-03-24
644	752	149.40	deposit	2023-12-23
645	669	139.80	deposit	2024-03-11
646	1681	257.00	withdrawal	2023-12-19
647	1143	276.40	withdrawal	2023-03-01
648	564	327.10	deposit	2023-12-07
649	1638	302.20	withdrawal	2024-05-13
650	1304	479.50	withdrawal	2024-02-28
651	488	64.20	withdrawal	2023-09-20
652	532	54.00	deposit	2023-03-27
653	188	406.60	withdrawal	2023-03-21
654	1027	132.70	deposit	2024-04-14
655	1005	200.00	deposit	2023-10-18
656	788	41.50	deposit	2023-04-28
657	39	26.80	withdrawal	2024-04-19
658	919	284.10	deposit	2023-07-31
659	100	243.60	withdrawal	2024-01-25
660	972	173.90	deposit	2023-07-20
661	1582	335.00	withdrawal	2023-09-17
662	659	499.20	deposit	2023-05-08
663	457	19.60	deposit	2024-03-08
664	1533	43.90	withdrawal	2023-03-01
665	989	210.10	withdrawal	2023-11-14
666	1241	433.40	withdrawal	2023-10-14
667	1436	312.30	withdrawal	2024-05-14
668	325	322.00	deposit	2023-03-08
669	1292	54.10	deposit	2024-01-14
670	38	79.70	deposit	2023-03-26
671	1211	386.70	deposit	2023-04-12
672	1022	447.40	withdrawal	2023-09-07
673	756	310.00	deposit	2023-06-01
674	737	339.10	deposit	2023-11-24
675	1114	168.80	deposit	2023-10-24
676	208	415.00	withdrawal	2023-11-17
677	1106	94.40	deposit	2023-04-12
678	151	136.00	deposit	2023-12-04
679	807	208.40	deposit	2023-05-03
680	96	133.20	withdrawal	2023-02-26
681	1587	20.70	withdrawal	2023-06-08
682	1456	416.50	withdrawal	2024-02-02
683	605	487.70	deposit	2023-08-14
684	1646	149.90	deposit	2023-10-16
685	1105	486.70	withdrawal	2023-09-24
686	1465	441.80	deposit	2024-03-08
687	1514	441.10	deposit	2023-11-24
688	17	46.80	deposit	2023-04-02
690	1633	27.30	withdrawal	2023-10-01
691	425	122.90	deposit	2023-03-17
692	678	225.60	withdrawal	2024-03-13
693	318	446.70	withdrawal	2023-09-21
694	506	473.30	withdrawal	2023-11-21
695	470	189.10	withdrawal	2023-10-01
696	1170	28.00	deposit	2023-03-21
697	576	214.90	withdrawal	2023-11-07
698	368	76.80	deposit	2023-08-06
699	1789	103.90	deposit	2023-01-14
700	1350	247.90	withdrawal	2024-05-09
701	1388	84.70	deposit	2024-01-02
702	63	451.30	deposit	2023-05-23
703	69	164.40	deposit	2023-01-22
704	1688	220.70	deposit	2023-02-11
705	592	163.10	withdrawal	2024-04-24
706	1604	300.60	withdrawal	2023-07-07
707	1025	252.90	withdrawal	2023-07-20
708	1155	447.40	deposit	2024-01-29
709	183	8.30	withdrawal	2024-02-22
710	964	23.00	deposit	2023-09-14
711	712	336.00	deposit	2024-01-22
712	131	200.00	deposit	2024-03-20
713	418	495.60	withdrawal	2023-11-03
714	1341	36.20	deposit	2024-01-16
715	705	128.30	withdrawal	2023-08-03
716	453	419.80	deposit	2024-01-06
717	39	345.20	deposit	2023-02-28
718	16	135.70	deposit	2024-05-31
719	1195	20.90	withdrawal	2024-01-08
720	1317	297.60	withdrawal	2023-04-25
721	1326	457.10	withdrawal	2023-03-26
722	1022	487.90	withdrawal	2023-03-15
723	177	210.50	withdrawal	2023-07-24
724	276	21.00	withdrawal	2023-03-29
725	206	377.30	withdrawal	2023-01-19
726	1651	469.80	withdrawal	2024-02-26
727	1135	228.10	withdrawal	2024-05-08
728	824	192.00	deposit	2024-02-16
729	138	100.50	withdrawal	2024-01-18
730	1137	367.10	deposit	2023-01-21
731	1416	325.40	withdrawal	2024-03-04
732	1421	446.50	deposit	2024-03-19
733	36	315.10	deposit	2023-05-05
734	921	217.70	deposit	2023-09-08
735	299	361.70	withdrawal	2024-02-02
736	831	238.70	withdrawal	2023-05-01
737	1443	457.70	withdrawal	2023-11-21
738	1124	361.00	withdrawal	2023-06-07
739	798	168.30	deposit	2024-04-27
740	1282	90.10	withdrawal	2023-12-08
741	1351	318.40	withdrawal	2024-01-12
742	1453	109.00	deposit	2023-12-02
743	1589	293.30	deposit	2024-04-29
744	936	495.30	withdrawal	2023-09-23
745	356	57.60	withdrawal	2023-03-03
746	1771	109.60	withdrawal	2023-09-23
747	1144	491.30	deposit	2023-10-07
748	1598	119.90	deposit	2023-01-28
749	693	187.00	deposit	2023-12-02
750	975	255.20	deposit	2023-03-19
751	122	197.60	deposit	2023-07-12
752	605	305.80	withdrawal	2024-04-22
753	1404	88.90	withdrawal	2024-01-24
754	68	126.70	withdrawal	2023-12-24
755	491	296.30	deposit	2023-09-09
756	973	378.80	deposit	2024-02-10
757	1220	495.80	deposit	2023-10-19
758	605	134.70	withdrawal	2024-04-14
759	322	48.10	deposit	2023-10-21
760	677	322.40	withdrawal	2023-05-26
761	625	498.70	deposit	2024-02-02
762	1107	144.30	deposit	2024-02-19
763	377	116.20	withdrawal	2023-11-26
764	791	399.50	withdrawal	2023-05-07
765	1433	122.50	withdrawal	2023-09-08
766	1000	54.30	deposit	2023-08-09
767	493	250.00	withdrawal	2023-03-28
768	237	462.10	withdrawal	2023-02-14
769	109	365.40	withdrawal	2023-10-05
770	1515	398.00	deposit	2023-06-26
771	502	272.10	withdrawal	2023-02-28
772	1751	227.30	deposit	2023-03-18
773	270	441.10	withdrawal	2023-03-13
774	609	58.60	deposit	2024-04-14
775	178	205.30	withdrawal	2024-01-18
776	284	317.90	deposit	2023-12-27
777	140	336.90	withdrawal	2023-12-08
778	541	38.50	deposit	2023-04-17
779	366	44.80	withdrawal	2023-11-07
780	173	347.20	withdrawal	2023-12-04
781	1173	299.60	deposit	2024-04-12
782	778	24.60	deposit	2024-05-09
783	996	99.40	withdrawal	2024-05-18
784	1031	377.90	deposit	2023-03-11
785	1668	321.10	deposit	2023-04-15
786	1657	115.80	deposit	2023-04-01
787	1758	398.40	deposit	2023-09-26
788	174	353.90	withdrawal	2023-01-30
789	320	461.00	withdrawal	2023-11-19
790	49	84.50	withdrawal	2023-03-20
791	1008	196.00	withdrawal	2024-01-08
792	1262	463.00	deposit	2024-05-28
793	112	42.50	deposit	2023-09-11
794	1105	265.60	withdrawal	2023-10-14
795	1488	146.40	withdrawal	2023-09-29
796	1374	246.90	deposit	2024-04-18
797	1668	191.00	deposit	2024-03-02
798	733	342.50	deposit	2023-10-03
799	26	291.30	withdrawal	2023-01-13
800	137	216.90	deposit	2023-02-26
801	1103	117.80	withdrawal	2024-03-27
802	555	276.40	withdrawal	2024-03-29
803	737	431.90	withdrawal	2024-05-10
804	542	239.90	deposit	2023-10-04
805	1465	420.40	withdrawal	2023-04-30
806	1464	102.40	deposit	2023-12-16
807	446	58.60	withdrawal	2024-01-22
808	1172	224.30	withdrawal	2023-07-30
809	1790	274.60	deposit	2024-01-26
810	96	486.40	deposit	2023-01-04
811	1651	497.20	withdrawal	2023-09-28
812	315	206.10	deposit	2024-03-20
813	1137	170.30	withdrawal	2023-06-12
814	601	313.30	withdrawal	2023-10-27
815	698	339.40	withdrawal	2023-01-22
816	768	380.30	withdrawal	2024-01-24
817	111	199.50	withdrawal	2023-05-29
818	615	260.70	deposit	2023-08-21
819	278	283.10	withdrawal	2023-07-06
820	878	76.10	deposit	2024-03-02
821	425	82.80	withdrawal	2023-06-20
822	1361	91.50	deposit	2024-03-30
823	1761	144.60	deposit	2024-04-24
824	1534	50.90	withdrawal	2023-03-09
825	200	388.50	withdrawal	2024-01-31
826	1343	229.30	deposit	2023-03-10
827	858	439.10	deposit	2023-08-04
828	830	119.80	withdrawal	2023-01-24
829	1252	153.90	deposit	2024-01-12
830	1498	234.70	withdrawal	2023-01-02
831	661	271.00	withdrawal	2023-04-03
832	1101	447.10	withdrawal	2024-05-26
833	381	386.80	withdrawal	2023-06-27
834	531	226.00	withdrawal	2023-07-31
835	500	358.00	deposit	2023-04-03
836	879	39.10	withdrawal	2023-09-29
837	183	428.40	withdrawal	2023-02-18
838	1642	110.70	deposit	2024-02-24
839	873	431.10	deposit	2023-07-08
840	1444	289.80	deposit	2023-04-04
841	267	310.30	deposit	2023-06-14
842	3	336.30	deposit	2024-04-28
843	60	255.40	deposit	2023-01-10
844	1575	218.60	deposit	2023-11-27
845	445	446.20	withdrawal	2023-08-18
846	1754	334.60	deposit	2023-05-12
847	1444	167.00	withdrawal	2023-10-26
848	1117	340.80	deposit	2023-11-18
849	53	102.80	withdrawal	2023-12-05
850	47	237.50	withdrawal	2024-04-30
851	1379	211.30	withdrawal	2023-03-19
852	1594	466.20	withdrawal	2023-06-21
853	407	449.50	withdrawal	2023-02-20
854	876	356.90	withdrawal	2023-02-21
855	1296	331.30	deposit	2023-10-27
856	816	132.80	withdrawal	2023-01-24
857	106	392.30	withdrawal	2024-01-24
858	930	286.60	deposit	2024-03-29
859	1097	480.70	withdrawal	2023-09-02
860	114	234.40	deposit	2023-05-01
861	1365	218.80	withdrawal	2023-06-20
862	474	47.90	deposit	2023-08-26
863	750	189.80	withdrawal	2024-03-25
864	1653	164.70	withdrawal	2024-01-24
865	1420	383.80	deposit	2023-11-07
866	652	419.10	withdrawal	2024-04-12
867	1115	500.60	deposit	2024-05-13
868	1702	50.60	deposit	2023-10-03
869	914	195.90	deposit	2023-03-01
870	840	97.60	deposit	2023-01-17
871	641	350.60	withdrawal	2024-03-16
872	1557	166.30	deposit	2023-09-21
873	953	39.00	deposit	2023-02-26
874	434	114.40	deposit	2024-03-20
875	1765	104.20	deposit	2023-10-23
876	988	55.70	withdrawal	2023-10-04
877	1782	59.80	deposit	2024-03-25
878	1713	426.20	withdrawal	2023-01-06
879	774	300.00	withdrawal	2023-06-25
880	301	424.20	withdrawal	2023-04-25
881	1564	460.60	deposit	2023-12-01
882	1328	316.80	deposit	2023-06-03
883	1290	131.70	withdrawal	2024-01-25
884	1602	373.50	withdrawal	2023-01-09
885	1036	198.50	deposit	2023-10-27
886	123	70.80	deposit	2023-06-17
887	1599	318.40	withdrawal	2023-04-14
888	1730	406.30	deposit	2024-04-09
889	1178	226.30	deposit	2024-04-24
890	1702	433.10	withdrawal	2024-01-28
891	1296	424.80	deposit	2023-01-03
892	1364	293.80	deposit	2023-01-06
893	862	69.10	deposit	2024-03-05
894	159	185.50	deposit	2023-07-24
895	1246	489.80	withdrawal	2023-10-19
896	1516	138.70	withdrawal	2023-02-11
897	1765	193.10	deposit	2023-11-03
898	31	451.50	withdrawal	2023-06-15
899	1119	316.60	withdrawal	2024-02-25
900	1401	443.40	deposit	2024-03-15
901	1451	78.00	withdrawal	2024-01-03
902	1257	460.40	withdrawal	2024-03-31
903	1698	168.50	withdrawal	2023-10-29
904	671	288.70	withdrawal	2023-12-07
905	1081	409.10	deposit	2024-03-01
906	1221	498.00	deposit	2023-05-15
907	389	288.90	withdrawal	2023-09-22
908	883	296.60	withdrawal	2023-08-24
909	810	358.70	withdrawal	2024-02-04
910	1275	421.50	deposit	2023-09-06
911	805	99.10	withdrawal	2023-02-24
912	195	201.90	deposit	2023-11-19
913	720	265.40	deposit	2024-04-12
914	1492	464.10	withdrawal	2023-05-01
915	1586	307.80	withdrawal	2023-01-16
916	1738	87.40	withdrawal	2024-03-14
917	536	440.90	withdrawal	2023-12-18
918	915	366.60	withdrawal	2023-01-14
919	567	370.10	deposit	2023-07-21
920	423	217.30	deposit	2023-05-04
921	1415	121.40	withdrawal	2023-07-14
922	641	440.20	withdrawal	2024-04-09
923	893	81.70	withdrawal	2023-07-27
924	1676	462.10	deposit	2023-04-15
925	593	26.00	deposit	2024-01-06
926	1550	316.30	withdrawal	2024-03-15
927	1366	261.90	withdrawal	2023-03-21
928	329	132.90	withdrawal	2024-04-14
929	431	498.20	withdrawal	2023-02-01
930	883	155.00	withdrawal	2023-11-19
931	1223	294.40	withdrawal	2023-02-22
932	583	251.30	deposit	2023-09-12
933	1489	405.90	deposit	2023-06-14
934	850	144.80	deposit	2023-11-29
935	489	28.90	deposit	2023-05-13
936	579	309.50	withdrawal	2024-02-25
937	70	468.10	deposit	2023-02-15
938	985	193.50	deposit	2023-09-29
939	399	464.70	withdrawal	2023-11-21
940	1668	423.40	withdrawal	2023-09-14
941	1431	75.00	withdrawal	2023-02-04
942	1320	283.50	withdrawal	2023-11-05
943	1767	435.60	deposit	2023-03-24
944	631	407.00	withdrawal	2024-05-09
945	735	406.30	withdrawal	2023-07-07
946	839	105.60	withdrawal	2023-05-25
947	1103	416.00	deposit	2023-12-01
948	291	233.90	withdrawal	2023-06-27
949	620	76.00	deposit	2024-05-18
950	904	291.70	deposit	2023-11-13
951	991	229.40	deposit	2023-07-28
952	1713	463.10	withdrawal	2024-05-25
953	1083	26.70	deposit	2023-06-17
954	743	478.50	deposit	2023-06-20
955	1449	449.60	withdrawal	2024-04-29
956	1786	441.40	deposit	2023-04-04
957	1401	221.20	withdrawal	2023-07-22
958	893	472.90	deposit	2023-11-25
959	612	137.70	deposit	2023-10-03
960	576	344.00	withdrawal	2023-07-23
961	1381	64.70	withdrawal	2024-03-14
962	1086	463.30	withdrawal	2024-04-13
963	285	468.70	deposit	2023-01-10
964	1345	51.40	deposit	2023-07-10
965	929	179.10	deposit	2024-01-21
966	118	469.60	withdrawal	2024-03-03
967	983	269.80	deposit	2024-01-27
968	1008	402.20	deposit	2023-10-18
969	982	36.60	withdrawal	2023-08-04
970	927	183.30	withdrawal	2023-03-28
971	1320	147.90	deposit	2023-10-08
972	1646	388.20	withdrawal	2023-01-20
973	366	413.00	deposit	2023-01-09
974	575	494.10	withdrawal	2023-12-31
975	275	241.70	deposit	2023-11-23
976	1345	200.50	withdrawal	2023-11-24
977	904	203.00	deposit	2023-11-04
978	475	259.50	withdrawal	2024-03-19
979	984	250.40	withdrawal	2023-07-21
980	488	347.80	withdrawal	2024-03-05
981	964	41.50	deposit	2023-01-12
982	74	158.40	deposit	2024-02-17
983	1113	92.60	deposit	2023-11-15
984	1409	301.90	deposit	2023-11-11
985	353	341.30	withdrawal	2024-04-20
986	555	76.80	deposit	2024-03-20
987	1274	454.10	withdrawal	2023-10-18
988	1708	113.30	withdrawal	2023-10-17
989	685	331.10	withdrawal	2023-09-10
990	597	90.80	deposit	2023-09-29
991	1186	129.30	withdrawal	2024-02-11
992	1598	69.30	deposit	2024-03-05
993	1491	83.60	deposit	2024-05-12
994	1300	498.60	withdrawal	2024-03-19
995	662	402.40	deposit	2023-04-16
996	133	404.50	deposit	2023-07-19
997	1544	212.20	deposit	2023-02-28
998	545	208.40	deposit	2023-03-28
999	1024	360.40	deposit	2023-11-11
1000	847	14.20	deposit	2023-10-24
1001	613	118.40	withdrawal	2024-02-18
1002	830	435.20	withdrawal	2023-10-28
1003	1675	99.30	withdrawal	2023-07-03
1004	1114	363.30	deposit	2024-01-22
1005	1054	414.20	withdrawal	2024-01-10
1006	51	479.90	deposit	2023-04-20
1007	1586	282.70	withdrawal	2023-11-26
1008	1096	393.20	deposit	2023-08-24
1009	554	62.40	deposit	2024-04-24
1010	774	167.10	withdrawal	2024-04-03
1011	1085	203.50	withdrawal	2023-03-08
1012	657	153.00	deposit	2024-05-06
1013	1148	256.20	withdrawal	2023-06-20
1014	674	375.30	deposit	2024-02-22
1015	1070	216.50	deposit	2023-11-23
1016	1012	319.80	deposit	2023-11-19
1017	264	75.60	deposit	2023-03-03
1018	694	104.30	withdrawal	2023-06-16
1019	1278	168.90	deposit	2024-04-28
1020	1743	112.80	deposit	2023-12-01
1021	1435	282.20	deposit	2023-05-31
1022	1013	222.90	withdrawal	2023-04-07
1023	1531	44.40	deposit	2024-04-13
1024	1010	280.60	withdrawal	2023-08-24
1025	1306	26.20	deposit	2023-04-22
1026	86	391.80	withdrawal	2024-02-08
1027	12	402.70	withdrawal	2024-01-28
1028	585	402.50	withdrawal	2023-09-16
1029	958	312.70	deposit	2023-03-14
1030	306	425.00	deposit	2023-03-04
1031	648	211.70	deposit	2023-06-27
1032	1102	199.60	withdrawal	2024-01-27
1033	1327	40.70	deposit	2023-10-18
1034	224	311.10	deposit	2023-11-11
1035	545	27.10	withdrawal	2023-09-10
1036	1489	54.30	deposit	2024-01-01
1037	694	77.50	withdrawal	2023-05-05
1038	509	34.20	withdrawal	2023-04-16
1039	913	308.30	withdrawal	2024-05-10
1040	413	171.10	withdrawal	2023-12-17
1041	734	393.70	withdrawal	2023-03-16
1042	191	73.50	deposit	2023-06-03
1043	1774	107.10	withdrawal	2024-03-07
1044	365	166.70	deposit	2023-04-15
1045	234	128.00	withdrawal	2023-07-24
1046	901	438.10	withdrawal	2023-06-20
1047	236	333.20	withdrawal	2023-11-29
1048	882	429.90	withdrawal	2023-01-09
1049	450	283.90	deposit	2023-08-30
1050	809	359.50	withdrawal	2023-05-15
1051	1141	187.20	withdrawal	2024-05-03
1052	227	259.10	deposit	2023-05-27
1053	1608	308.30	deposit	2023-12-04
1054	872	201.20	deposit	2023-10-12
1055	632	40.50	deposit	2023-05-28
1056	642	422.00	deposit	2024-05-14
1057	1257	53.10	withdrawal	2023-02-06
1058	1164	92.50	deposit	2023-07-23
1059	1623	160.50	withdrawal	2023-01-13
1060	544	492.30	deposit	2024-01-14
1061	1257	367.60	withdrawal	2023-12-02
1062	677	460.90	deposit	2023-06-09
1063	1426	132.60	deposit	2023-06-08
1064	311	24.00	withdrawal	2023-05-19
1065	1429	149.90	deposit	2023-03-12
1066	970	65.30	deposit	2023-09-01
1067	745	484.10	deposit	2023-08-19
1068	1461	373.50	withdrawal	2023-07-08
1069	1581	178.30	deposit	2023-02-27
1070	1284	199.20	withdrawal	2023-03-03
1071	853	152.80	deposit	2023-04-05
1072	1681	143.50	withdrawal	2024-01-12
1073	1315	478.20	deposit	2023-08-13
1074	714	314.70	deposit	2023-10-16
1075	1653	240.60	deposit	2024-03-21
1076	1334	421.70	deposit	2023-09-30
1077	942	361.60	withdrawal	2024-03-20
1078	1605	19.60	deposit	2024-03-18
1079	1612	247.10	deposit	2023-02-22
1080	55	257.70	deposit	2023-03-23
1081	927	338.50	withdrawal	2023-10-25
1082	231	29.70	withdrawal	2024-04-08
1083	1617	334.60	withdrawal	2023-02-27
1084	816	246.70	deposit	2023-06-24
1085	985	492.70	withdrawal	2024-02-01
1086	85	60.30	deposit	2023-10-29
1087	1093	106.70	withdrawal	2024-02-16
1088	1596	423.10	withdrawal	2024-01-13
1089	1381	200.60	deposit	2024-04-20
1090	1283	221.00	deposit	2023-12-14
1091	1616	457.40	deposit	2023-05-25
1092	177	371.60	withdrawal	2024-03-01
1093	1781	42.20	deposit	2024-01-06
1094	420	438.20	withdrawal	2023-09-25
1095	1217	186.30	withdrawal	2023-05-28
1096	1015	183.60	deposit	2023-11-17
1097	442	118.90	withdrawal	2023-12-30
1098	645	444.60	withdrawal	2023-03-30
1099	1251	252.30	withdrawal	2024-02-02
1100	1591	342.10	withdrawal	2023-05-25
1101	319	134.30	deposit	2023-04-27
1102	1355	453.40	deposit	2023-09-08
1103	1039	133.30	deposit	2023-03-25
1104	342	297.00	deposit	2024-02-06
1105	1785	135.30	deposit	2024-05-09
1106	1552	299.80	deposit	2023-03-13
1107	477	331.00	withdrawal	2023-06-08
1108	1031	288.40	deposit	2023-07-06
1109	462	167.60	deposit	2023-08-18
1110	824	217.00	withdrawal	2023-09-04
1111	282	454.00	deposit	2024-03-19
1112	240	248.40	deposit	2024-01-26
1113	1785	373.00	withdrawal	2023-11-18
1114	1375	340.90	withdrawal	2023-12-19
1115	858	336.00	deposit	2023-09-09
1116	888	122.30	withdrawal	2023-01-07
1117	999	185.10	withdrawal	2023-08-23
1118	1743	454.10	withdrawal	2023-04-22
1119	1400	448.40	deposit	2023-05-11
1120	846	233.50	deposit	2024-04-13
1121	1322	50.80	withdrawal	2023-12-24
1122	1732	37.50	withdrawal	2023-03-06
1123	152	120.50	withdrawal	2023-09-02
1124	1766	222.20	deposit	2023-07-16
1125	1497	35.70	deposit	2023-04-14
1126	1564	26.10	deposit	2023-07-22
1127	707	63.10	deposit	2023-02-28
1128	1472	144.10	withdrawal	2023-01-09
1129	942	29.20	deposit	2023-11-26
1130	480	137.10	deposit	2023-08-19
1131	227	344.20	withdrawal	2023-04-30
1132	553	203.70	deposit	2023-12-18
1133	338	59.70	deposit	2023-07-16
1134	747	190.50	withdrawal	2023-02-10
1135	452	346.00	deposit	2023-10-05
1136	159	332.20	deposit	2023-10-24
1137	1201	141.60	withdrawal	2023-08-23
1138	1593	203.70	withdrawal	2023-11-22
1139	1216	163.70	withdrawal	2023-11-28
1140	314	37.10	withdrawal	2023-08-19
1141	839	98.70	deposit	2023-01-28
1142	763	466.70	deposit	2023-12-25
1143	412	137.70	deposit	2024-04-05
1144	393	48.80	withdrawal	2023-04-30
1145	1628	110.20	deposit	2023-11-01
1146	517	44.50	withdrawal	2023-08-01
1147	21	142.70	deposit	2024-05-26
1148	1483	438.70	withdrawal	2024-05-31
1149	1445	353.10	withdrawal	2023-04-14
1150	927	476.30	deposit	2023-07-16
1151	1786	5.50	withdrawal	2023-01-13
1152	1285	416.20	deposit	2024-03-29
1153	1344	257.00	withdrawal	2024-02-19
1154	10	145.20	withdrawal	2024-04-05
1155	1241	26.00	withdrawal	2023-08-17
1156	224	223.60	deposit	2023-07-22
1157	413	82.80	withdrawal	2023-09-11
1158	1668	250.00	withdrawal	2023-09-21
1159	826	178.30	withdrawal	2024-04-27
1160	573	200.70	withdrawal	2023-04-05
1161	1141	301.30	deposit	2023-09-16
1162	1289	100.10	deposit	2024-02-03
1163	81	453.00	withdrawal	2023-01-12
1164	1757	43.60	deposit	2023-12-21
1165	1249	26.70	withdrawal	2023-11-20
1166	726	299.50	withdrawal	2024-01-24
1167	438	182.00	withdrawal	2024-05-10
1168	932	207.10	deposit	2023-02-02
1169	1594	100.50	withdrawal	2023-12-02
1170	138	433.40	withdrawal	2023-02-16
1171	1373	338.60	deposit	2023-07-10
1172	86	253.80	withdrawal	2023-04-12
1173	886	318.10	withdrawal	2024-03-19
1174	1060	435.80	deposit	2023-09-20
1175	1025	160.80	deposit	2023-01-01
1176	103	172.30	deposit	2023-02-02
1177	1455	51.70	deposit	2023-12-23
1178	373	374.20	deposit	2023-11-23
1179	1109	315.90	withdrawal	2023-03-12
1180	278	257.50	withdrawal	2023-08-10
1181	98	141.70	deposit	2024-01-22
1182	908	288.20	withdrawal	2023-01-07
1183	1715	135.00	withdrawal	2024-02-19
1184	1391	346.80	withdrawal	2023-01-03
1185	453	25.50	withdrawal	2023-07-24
1186	225	270.90	deposit	2024-03-16
1187	464	150.00	deposit	2023-09-09
1188	770	78.50	withdrawal	2023-11-17
1189	41	87.30	withdrawal	2023-11-09
1190	1357	444.30	deposit	2023-12-10
1191	1038	231.70	withdrawal	2024-01-01
1192	437	54.50	withdrawal	2024-01-28
1193	878	145.50	withdrawal	2023-11-03
1194	710	262.90	deposit	2024-03-10
1195	1523	464.20	deposit	2023-07-16
1196	908	357.10	deposit	2023-12-26
1197	422	106.60	deposit	2024-01-27
1198	155	417.40	withdrawal	2023-01-06
1199	476	409.50	withdrawal	2023-04-09
1200	403	414.40	withdrawal	2023-11-19
1201	1029	86.60	deposit	2023-10-12
1202	859	336.00	deposit	2023-06-24
1203	1635	98.20	deposit	2024-03-10
1204	197	442.30	withdrawal	2023-02-01
1205	412	51.30	deposit	2023-11-02
1206	193	210.90	deposit	2024-02-29
1207	16	467.60	deposit	2024-02-25
1208	376	214.50	deposit	2023-03-28
1209	668	279.50	withdrawal	2023-06-25
1210	304	64.30	deposit	2023-09-22
1211	1790	355.60	withdrawal	2023-10-10
1212	1774	216.40	deposit	2023-05-18
1213	1518	31.20	withdrawal	2023-12-07
1214	230	140.80	withdrawal	2024-01-11
1215	272	254.70	deposit	2023-11-24
1216	88	10.60	withdrawal	2023-09-26
1217	182	397.90	deposit	2024-03-30
1218	21	295.50	withdrawal	2024-05-16
1219	1111	101.20	withdrawal	2023-05-16
1220	1728	80.20	deposit	2023-05-09
1221	312	476.80	deposit	2023-09-08
1222	692	22.10	deposit	2023-03-07
1223	962	323.20	withdrawal	2023-03-18
1224	227	42.30	deposit	2023-12-30
1225	1461	254.60	deposit	2024-02-16
1226	861	190.30	deposit	2024-01-25
1227	1028	255.50	withdrawal	2023-07-29
1228	978	291.60	deposit	2023-08-22
1229	1227	315.90	withdrawal	2023-10-01
1230	1018	388.60	deposit	2023-05-11
1231	1404	63.40	withdrawal	2024-02-17
1232	1012	163.30	deposit	2024-04-23
1233	479	418.70	deposit	2023-04-04
1234	1006	264.70	withdrawal	2023-08-18
1235	713	12.80	withdrawal	2023-07-19
1236	963	333.10	withdrawal	2023-08-16
1237	1276	433.40	withdrawal	2023-11-23
1238	675	96.00	withdrawal	2023-05-29
1239	1466	286.40	deposit	2024-05-30
1240	1529	138.40	deposit	2024-05-08
1241	1595	470.40	deposit	2023-01-03
1242	731	374.30	withdrawal	2023-05-25
1243	1568	241.80	deposit	2023-11-08
1244	549	154.20	deposit	2024-05-10
1245	67	392.00	deposit	2024-03-28
1246	1701	408.90	withdrawal	2024-03-08
1247	902	205.40	deposit	2023-12-29
1248	1384	343.40	deposit	2023-10-24
1249	796	5.20	withdrawal	2024-05-02
1250	1706	14.60	deposit	2024-02-13
1251	1743	256.80	withdrawal	2023-12-05
1252	478	371.00	deposit	2023-05-15
1253	1531	206.30	deposit	2023-02-23
1254	519	336.80	deposit	2023-06-27
1255	1408	32.30	deposit	2023-04-18
1256	80	414.80	deposit	2023-05-04
1257	144	151.90	deposit	2023-09-09
1258	775	281.50	deposit	2023-09-13
1259	73	138.80	withdrawal	2023-04-12
1260	526	441.70	deposit	2023-11-26
1261	1114	241.40	deposit	2023-02-11
1262	1127	282.00	withdrawal	2023-02-09
1263	222	428.40	withdrawal	2023-08-10
1264	510	385.80	withdrawal	2024-03-10
1265	196	286.40	withdrawal	2024-02-11
1266	1401	154.10	withdrawal	2023-08-09
1267	216	381.00	withdrawal	2023-01-16
1268	134	106.60	withdrawal	2024-05-22
1269	1055	392.20	withdrawal	2024-05-30
1270	1087	418.20	withdrawal	2024-05-22
1271	207	290.50	deposit	2024-03-14
1272	956	393.30	withdrawal	2023-12-28
1273	1614	461.00	deposit	2024-05-22
1274	905	443.90	deposit	2023-10-20
1275	1623	448.60	withdrawal	2023-02-09
1276	589	139.80	deposit	2024-05-31
1277	861	51.80	deposit	2023-12-31
1278	385	459.50	withdrawal	2023-10-16
1279	459	9.10	withdrawal	2023-12-16
1280	89	336.20	withdrawal	2023-10-18
1281	244	491.70	withdrawal	2024-03-18
1282	447	335.30	deposit	2023-12-05
1283	47	112.90	withdrawal	2023-09-02
1284	1229	228.80	deposit	2024-03-23
1285	18	189.00	withdrawal	2023-12-30
1286	254	152.70	deposit	2023-03-27
1287	858	494.40	withdrawal	2024-04-13
1288	669	150.70	deposit	2024-05-20
1289	1273	13.80	withdrawal	2023-06-19
1290	1168	379.00	withdrawal	2023-07-23
1291	594	138.40	deposit	2023-07-26
1292	778	378.60	deposit	2023-12-21
1293	1290	224.20	withdrawal	2023-09-13
1294	1667	472.60	withdrawal	2024-04-01
1295	1290	429.50	withdrawal	2023-12-22
1296	930	407.30	deposit	2023-04-15
1297	864	143.00	withdrawal	2023-04-12
1298	744	468.70	withdrawal	2023-10-07
1299	487	6.20	withdrawal	2024-03-12
1300	1790	320.30	withdrawal	2023-06-24
1301	1398	150.10	deposit	2023-12-04
1302	823	41.20	deposit	2023-12-20
1303	1452	498.40	deposit	2023-09-10
1304	1148	187.80	deposit	2023-12-25
1305	1463	286.30	withdrawal	2023-04-17
1306	1296	467.60	deposit	2023-06-26
1307	903	6.00	deposit	2023-08-02
1308	1717	449.90	withdrawal	2023-10-27
1309	221	64.00	deposit	2024-02-27
1310	1442	77.20	deposit	2023-07-16
1311	1681	415.60	deposit	2023-01-09
1312	1068	278.70	deposit	2023-01-05
1313	1266	204.60	withdrawal	2023-09-10
1314	1467	67.00	deposit	2024-05-15
1315	794	283.80	deposit	2024-01-17
1316	259	298.10	deposit	2023-06-04
1317	398	111.30	deposit	2023-08-22
1318	1057	95.10	withdrawal	2024-04-17
1319	1186	200.80	deposit	2023-02-14
1320	1062	170.10	withdrawal	2023-11-08
1321	937	258.40	withdrawal	2023-10-25
1322	904	255.80	withdrawal	2024-05-29
1323	34	257.90	deposit	2023-10-03
1324	856	169.10	deposit	2023-04-02
1325	49	487.40	deposit	2023-02-23
1326	1012	343.10	withdrawal	2023-03-11
1327	751	153.60	withdrawal	2024-01-07
1328	1473	11.30	deposit	2024-01-17
1329	68	421.20	withdrawal	2024-02-16
1330	335	209.10	withdrawal	2023-02-10
1331	128	13.50	deposit	2023-11-02
1332	1260	358.60	deposit	2023-04-19
1333	203	137.50	withdrawal	2023-01-13
1334	1792	383.30	deposit	2024-04-05
1335	1399	263.30	withdrawal	2023-12-21
1336	437	64.60	withdrawal	2023-07-06
1337	273	199.80	deposit	2023-08-13
1338	770	347.00	deposit	2023-02-13
1339	1149	142.70	withdrawal	2023-06-11
1340	1035	457.80	deposit	2023-05-28
1341	1629	105.20	deposit	2023-12-17
1342	73	76.20	deposit	2024-04-07
1343	1078	286.50	deposit	2023-09-13
1344	1449	10.10	deposit	2023-09-14
1345	604	123.50	withdrawal	2024-02-19
1346	1663	471.90	withdrawal	2023-12-19
1347	680	178.60	withdrawal	2024-03-07
1348	417	181.70	deposit	2023-07-21
1349	958	322.30	deposit	2023-03-11
1350	1331	258.70	withdrawal	2023-11-17
1351	1263	166.20	deposit	2023-09-12
1352	381	476.60	withdrawal	2023-04-12
1353	1553	130.00	withdrawal	2023-05-09
1354	1028	151.70	deposit	2023-04-04
1355	1798	329.70	withdrawal	2023-09-04
1356	158	137.50	deposit	2024-01-09
1357	1011	103.80	deposit	2023-03-18
1358	1511	102.80	deposit	2023-10-22
1359	685	163.00	withdrawal	2023-01-05
1360	1680	80.30	deposit	2023-02-18
1361	129	346.90	deposit	2023-09-09
1362	471	135.40	deposit	2023-12-27
1363	670	296.30	deposit	2023-09-29
1364	1638	127.40	withdrawal	2023-11-04
1365	374	398.50	deposit	2024-03-01
1366	1753	158.40	withdrawal	2023-12-10
1367	1184	468.10	deposit	2024-04-15
1368	379	453.60	deposit	2024-01-27
1369	605	230.00	deposit	2024-02-22
1370	84	426.90	withdrawal	2024-04-28
1371	1784	335.70	deposit	2023-03-26
1372	581	396.40	deposit	2023-08-27
1373	221	31.90	withdrawal	2023-11-11
1374	503	136.00	withdrawal	2024-04-23
1375	1357	214.10	withdrawal	2023-11-07
1376	251	387.80	deposit	2023-05-02
1377	1546	461.10	deposit	2023-03-18
1378	908	401.00	deposit	2024-01-01
1379	331	312.70	deposit	2023-12-23
1380	21	372.20	withdrawal	2023-06-14
1381	670	367.60	deposit	2023-06-29
1382	1500	263.50	withdrawal	2023-01-27
1383	1773	457.30	withdrawal	2024-05-09
1384	712	255.00	withdrawal	2023-12-28
1385	1250	252.30	withdrawal	2024-04-03
1386	716	476.10	withdrawal	2023-09-15
1387	1625	307.90	deposit	2023-07-05
1388	538	322.30	withdrawal	2024-01-11
1389	1675	320.80	deposit	2024-02-12
1390	719	138.00	withdrawal	2023-03-07
1391	259	82.20	withdrawal	2023-07-18
1392	1631	154.10	deposit	2024-04-17
1393	269	48.70	withdrawal	2023-08-06
1394	124	465.30	withdrawal	2023-11-10
1395	937	9.20	deposit	2024-04-03
1396	1502	169.70	withdrawal	2024-04-02
1397	1141	307.80	deposit	2023-05-17
1398	1155	112.80	withdrawal	2023-11-23
1399	399	109.50	withdrawal	2023-10-27
1400	1103	28.60	withdrawal	2024-01-22
1401	711	245.70	withdrawal	2024-03-22
1402	197	51.10	withdrawal	2023-01-30
1403	1321	366.80	deposit	2023-01-18
1404	1782	386.60	deposit	2023-01-13
1405	1105	438.90	withdrawal	2023-03-15
1406	359	483.80	withdrawal	2023-09-14
1407	448	455.20	deposit	2023-02-04
1408	1278	378.80	deposit	2023-09-18
1409	133	44.50	withdrawal	2024-02-16
1410	1601	16.80	withdrawal	2023-08-29
1411	1242	209.20	withdrawal	2024-01-07
1412	1210	383.30	deposit	2023-03-09
1413	1373	215.40	deposit	2023-09-06
1414	134	275.40	deposit	2023-02-26
1415	49	384.00	deposit	2023-01-02
1416	1786	75.30	deposit	2023-01-22
1417	1574	15.40	withdrawal	2023-12-15
1418	146	361.90	deposit	2024-01-11
1419	416	208.50	withdrawal	2024-05-26
1420	422	314.20	withdrawal	2024-01-22
1421	493	129.80	deposit	2023-02-12
1422	1395	226.60	deposit	2024-04-28
1423	1129	114.10	deposit	2024-02-23
1424	218	264.70	deposit	2023-12-08
1425	379	455.00	deposit	2023-10-19
1426	247	80.80	deposit	2023-09-24
1427	1423	403.90	withdrawal	2024-01-03
1428	1655	449.40	deposit	2023-12-06
1429	190	10.80	deposit	2023-12-22
1430	949	13.40	withdrawal	2023-03-08
1431	633	15.00	deposit	2023-07-10
1432	500	16.80	withdrawal	2023-12-30
1433	697	53.40	withdrawal	2023-05-13
1434	538	44.00	deposit	2023-11-01
1435	1541	332.10	deposit	2023-05-04
1436	132	59.00	withdrawal	2024-05-12
1437	761	440.10	deposit	2023-10-11
1438	178	116.00	withdrawal	2023-03-17
1439	905	491.20	withdrawal	2023-05-23
1440	1330	173.00	withdrawal	2023-07-06
1441	846	207.40	deposit	2023-06-27
1442	230	273.10	withdrawal	2023-04-27
1443	213	420.40	deposit	2023-10-07
1444	436	483.90	withdrawal	2024-02-05
1445	961	94.90	withdrawal	2024-04-24
1446	284	419.90	deposit	2023-10-06
1447	45	179.20	deposit	2023-01-17
1448	990	394.50	withdrawal	2023-03-02
1449	1476	379.20	withdrawal	2023-08-18
1450	342	186.60	deposit	2023-03-03
1451	123	33.00	withdrawal	2023-07-08
1452	1157	224.00	withdrawal	2023-01-26
1453	578	429.40	withdrawal	2024-01-16
1454	339	329.00	withdrawal	2023-12-10
1455	168	85.80	withdrawal	2023-03-13
1456	92	475.80	deposit	2024-02-27
1457	1308	304.00	deposit	2023-10-05
1458	465	459.50	withdrawal	2023-09-12
1459	550	152.10	deposit	2023-03-07
1460	1785	78.20	withdrawal	2023-11-12
1461	1502	134.50	deposit	2023-05-19
1462	827	49.70	deposit	2023-10-11
1463	50	347.10	deposit	2024-03-04
1464	268	72.40	withdrawal	2024-05-25
1465	1396	43.20	withdrawal	2023-11-25
1466	1275	35.60	deposit	2024-04-08
1467	1685	402.60	deposit	2023-03-11
1468	289	398.00	withdrawal	2023-09-01
1469	991	238.80	deposit	2024-05-01
1470	686	58.90	withdrawal	2024-01-22
1471	1139	93.00	deposit	2023-10-14
1472	695	100.00	deposit	2023-12-23
1473	1603	170.00	withdrawal	2023-03-29
1474	1422	130.80	withdrawal	2023-11-03
1475	1315	259.80	deposit	2024-04-29
1476	843	81.50	withdrawal	2024-03-07
1477	1340	109.50	withdrawal	2023-03-13
1478	1588	356.80	deposit	2023-10-17
1479	421	56.00	deposit	2023-09-03
1480	1748	292.20	deposit	2024-01-31
1481	1640	332.80	withdrawal	2024-05-01
1482	345	278.10	deposit	2023-02-13
1483	626	342.00	withdrawal	2024-02-04
1484	19	10.80	withdrawal	2024-02-04
1485	896	182.60	deposit	2023-02-02
1486	1460	297.20	deposit	2023-05-12
1487	1566	330.50	withdrawal	2024-01-22
1488	1154	112.30	withdrawal	2023-05-25
1489	1498	317.00	deposit	2023-04-19
1490	452	398.40	deposit	2023-10-13
1491	468	264.90	withdrawal	2024-04-29
1492	680	363.30	deposit	2023-09-27
1493	1358	149.30	withdrawal	2023-07-29
1494	4	174.30	withdrawal	2024-04-23
1495	919	101.50	withdrawal	2023-10-19
1496	1485	204.40	withdrawal	2023-11-27
1497	1402	125.90	deposit	2023-06-06
1498	960	164.30	withdrawal	2023-06-28
1499	91	460.50	withdrawal	2023-12-31
1500	75	441.20	deposit	2023-12-14
1501	451	472.20	deposit	2023-08-11
1502	114	461.60	deposit	2023-10-11
1503	97	447.00	deposit	2023-10-08
1504	1506	250.00	deposit	2024-04-30
1505	1454	213.60	deposit	2024-02-26
1506	1725	209.00	withdrawal	2024-04-19
1507	362	272.70	withdrawal	2023-10-17
1508	1469	194.70	withdrawal	2023-09-27
1509	321	474.80	deposit	2023-10-27
1510	1109	81.20	deposit	2023-07-25
1511	825	361.20	deposit	2023-12-10
1512	265	211.50	deposit	2023-09-04
1513	851	194.20	withdrawal	2023-08-09
1514	1683	404.80	withdrawal	2023-02-04
1515	1517	238.60	withdrawal	2023-12-11
1516	312	404.30	deposit	2023-05-27
1517	736	493.90	deposit	2023-02-03
1518	413	470.90	withdrawal	2024-01-14
1519	635	96.90	withdrawal	2024-05-04
1520	429	348.20	deposit	2023-11-28
1521	1634	36.30	withdrawal	2023-10-09
1522	1158	182.10	deposit	2023-08-02
1523	1381	237.50	withdrawal	2023-06-30
1524	1632	113.70	withdrawal	2023-03-16
1525	918	315.00	withdrawal	2023-04-07
1526	1682	45.20	withdrawal	2023-12-22
1527	1489	264.80	withdrawal	2023-09-17
1528	1174	350.50	deposit	2023-09-05
1529	1579	91.70	deposit	2024-02-19
1530	821	92.60	withdrawal	2023-09-09
1531	795	454.90	deposit	2023-06-09
1532	1546	20.20	withdrawal	2024-03-11
1533	1793	485.00	withdrawal	2024-03-04
1534	1298	238.70	deposit	2023-05-05
1535	157	157.40	withdrawal	2024-01-16
1536	20	417.20	withdrawal	2024-03-23
1537	1313	358.40	withdrawal	2023-12-08
1538	442	131.60	deposit	2024-05-30
1539	792	300.60	deposit	2023-03-31
1540	481	401.70	deposit	2024-04-18
1541	841	329.50	deposit	2023-02-22
1542	117	452.90	withdrawal	2024-04-19
1543	1267	270.40	withdrawal	2024-05-12
1544	780	147.60	deposit	2023-07-26
1545	257	17.50	deposit	2023-07-17
1546	1287	426.90	deposit	2023-07-19
1547	1455	43.10	withdrawal	2023-02-27
1548	352	343.90	deposit	2023-09-30
1549	1388	286.00	withdrawal	2024-04-21
1550	954	461.00	deposit	2023-06-17
1551	1565	7.40	deposit	2024-01-06
1552	1783	425.90	withdrawal	2023-11-18
1553	272	425.70	withdrawal	2023-03-25
1554	1649	125.50	withdrawal	2024-02-09
1555	724	182.10	deposit	2024-03-05
1556	474	221.30	withdrawal	2023-01-19
1557	98	153.90	withdrawal	2023-06-19
1558	1400	497.70	withdrawal	2023-11-17
1559	885	103.00	deposit	2023-03-17
1560	482	142.70	withdrawal	2023-11-07
1561	1508	359.70	deposit	2024-02-19
1562	1028	52.20	deposit	2023-04-18
1563	1491	148.10	deposit	2024-04-25
1564	1569	124.70	deposit	2023-01-28
1565	475	170.60	deposit	2023-08-30
1566	1506	288.20	deposit	2023-01-09
1567	1019	131.90	withdrawal	2023-05-18
1568	1352	243.30	deposit	2023-12-31
1569	1134	223.70	withdrawal	2023-07-06
1570	905	27.10	deposit	2024-01-06
1571	1217	132.20	withdrawal	2023-09-29
1572	1141	317.30	deposit	2024-03-11
1573	1288	141.50	withdrawal	2023-10-26
1574	1169	205.90	withdrawal	2024-05-17
1575	1261	39.30	withdrawal	2024-02-01
1576	1591	375.70	deposit	2023-08-16
1577	41	239.50	withdrawal	2023-11-02
1578	904	262.20	deposit	2023-03-10
1579	1300	33.00	deposit	2023-10-14
1580	856	134.20	deposit	2023-06-17
1581	779	377.70	withdrawal	2023-04-28
1582	133	453.60	withdrawal	2023-05-30
1583	911	94.30	deposit	2023-01-04
1584	646	382.20	withdrawal	2023-02-14
1585	1553	490.90	deposit	2023-07-16
1586	229	412.10	withdrawal	2023-02-09
1587	179	16.70	deposit	2024-02-03
1588	4	429.20	deposit	2024-02-11
1589	1623	391.20	withdrawal	2023-04-22
1590	398	206.30	withdrawal	2024-04-29
1591	84	246.40	deposit	2023-02-05
1592	930	62.40	deposit	2023-03-03
1593	108	112.80	deposit	2023-01-16
1594	1035	388.00	deposit	2023-05-30
1595	289	259.10	withdrawal	2023-07-18
1596	766	276.80	deposit	2024-01-02
1597	1170	425.20	deposit	2023-08-29
1598	154	125.30	deposit	2023-09-21
1599	229	461.10	withdrawal	2024-02-21
1600	1460	331.10	deposit	2024-03-13
1601	553	96.20	withdrawal	2024-01-08
1602	1586	52.70	deposit	2023-08-13
1603	861	69.90	deposit	2023-12-12
1604	795	285.70	deposit	2023-11-28
1605	957	318.10	withdrawal	2024-02-07
1606	727	221.30	deposit	2023-05-03
1607	1601	404.10	withdrawal	2023-01-16
1608	1090	135.10	deposit	2024-05-13
1609	1119	40.10	withdrawal	2024-02-16
1610	961	26.00	withdrawal	2024-02-07
1611	647	239.40	deposit	2023-11-25
1612	1016	382.50	withdrawal	2023-04-10
1613	299	15.40	deposit	2023-12-12
1614	648	289.10	deposit	2023-09-11
1615	996	308.00	deposit	2024-02-14
1616	141	423.10	withdrawal	2023-03-30
1617	126	18.70	deposit	2024-03-06
1618	1667	402.80	withdrawal	2024-02-14
1619	940	294.10	withdrawal	2023-08-18
1620	718	91.40	deposit	2023-04-24
1621	352	285.40	deposit	2023-08-19
1622	1107	95.70	withdrawal	2023-12-31
1623	1761	245.00	withdrawal	2023-03-02
1624	1602	31.70	deposit	2023-07-15
1625	274	437.70	deposit	2024-03-13
1626	247	433.80	withdrawal	2023-07-12
1627	174	289.80	withdrawal	2024-05-05
1628	1733	476.70	deposit	2024-03-28
1629	353	107.50	deposit	2023-09-22
1630	1575	214.70	deposit	2023-10-14
1631	1226	491.80	withdrawal	2023-12-27
1632	1765	85.70	withdrawal	2023-11-25
1633	189	22.30	withdrawal	2023-01-18
1634	836	434.90	withdrawal	2023-09-05
1635	867	467.10	deposit	2023-04-11
1636	189	380.10	withdrawal	2023-06-20
1637	1749	363.90	deposit	2023-11-23
1638	603	31.10	withdrawal	2023-09-14
1639	436	112.30	withdrawal	2023-07-04
1640	965	10.90	withdrawal	2023-05-17
1641	934	100.60	withdrawal	2023-04-18
1642	1591	316.80	deposit	2024-01-28
1643	1098	458.40	withdrawal	2023-09-09
1644	1435	145.60	withdrawal	2023-06-28
1645	257	329.80	deposit	2023-03-16
1646	159	68.10	deposit	2023-03-01
1647	432	346.60	withdrawal	2023-02-18
1648	39	119.30	withdrawal	2023-02-05
1649	1037	35.40	withdrawal	2023-11-26
1650	1643	256.40	deposit	2023-07-12
1651	231	240.90	deposit	2024-04-21
1652	1083	465.10	withdrawal	2023-08-24
1653	703	282.70	withdrawal	2023-07-08
1654	102	46.10	deposit	2023-11-24
1655	1304	340.20	withdrawal	2024-02-25
1656	929	252.00	withdrawal	2023-07-22
1657	56	45.60	withdrawal	2024-01-08
1658	648	412.40	deposit	2023-10-01
1659	1187	259.50	deposit	2024-03-10
1660	503	172.00	withdrawal	2024-02-08
1661	1230	299.50	deposit	2023-11-14
1662	1685	184.00	withdrawal	2023-07-16
1663	748	16.70	withdrawal	2024-04-15
1664	1416	260.40	deposit	2024-05-09
1665	1043	355.70	withdrawal	2024-05-12
1666	627	330.00	withdrawal	2023-07-02
1667	1037	77.90	deposit	2023-07-23
1668	626	74.00	deposit	2024-03-11
1669	269	245.30	deposit	2024-02-18
1670	1091	116.90	deposit	2024-05-16
1671	1312	40.10	withdrawal	2024-01-31
1672	927	489.20	withdrawal	2023-02-05
1673	798	222.40	deposit	2023-07-24
1674	165	115.80	withdrawal	2023-12-03
1675	1593	280.60	deposit	2023-04-02
1676	774	288.90	withdrawal	2023-08-03
1677	1433	169.80	withdrawal	2023-11-27
1678	1601	353.20	deposit	2023-07-30
1679	756	436.50	deposit	2023-05-19
1680	22	241.10	withdrawal	2023-07-01
1681	727	377.50	deposit	2023-05-12
1682	562	106.50	deposit	2023-09-03
1683	1482	157.70	deposit	2023-06-27
1684	1024	368.90	deposit	2024-02-06
1685	170	408.50	withdrawal	2023-08-29
1686	1348	474.70	withdrawal	2023-07-06
1687	42	45.50	deposit	2023-10-01
1688	1718	254.50	withdrawal	2023-04-18
1689	1418	93.60	withdrawal	2023-10-11
1690	1322	39.00	withdrawal	2023-06-27
1691	472	29.10	deposit	2023-02-21
1692	51	150.80	withdrawal	2023-11-24
1693	1758	55.30	withdrawal	2023-01-05
1694	443	360.80	deposit	2024-01-18
1695	267	101.30	deposit	2023-02-16
1696	1516	411.80	withdrawal	2023-09-01
1697	1112	32.80	deposit	2024-04-16
1698	786	138.70	withdrawal	2024-05-23
1699	301	102.80	deposit	2024-01-31
1700	400	61.40	withdrawal	2023-12-02
1701	1421	53.20	withdrawal	2023-08-21
1702	408	428.50	withdrawal	2023-12-09
1703	1675	88.50	deposit	2023-04-27
1704	1476	446.20	withdrawal	2024-04-01
1705	726	443.70	withdrawal	2023-04-23
1706	1323	137.90	withdrawal	2023-05-05
1707	1498	13.40	withdrawal	2024-04-28
1708	1251	16.20	withdrawal	2023-06-06
1709	1610	385.00	deposit	2023-11-29
1710	922	180.80	withdrawal	2023-01-18
1711	220	271.10	deposit	2023-01-04
1712	1138	489.60	withdrawal	2023-03-29
1713	1004	368.50	deposit	2023-04-06
1714	1445	86.70	withdrawal	2023-02-09
1715	1369	212.90	deposit	2023-02-18
1716	702	487.50	deposit	2023-09-26
1717	743	355.00	deposit	2024-01-29
1718	1279	115.90	deposit	2023-06-07
1719	1036	216.50	withdrawal	2023-02-22
1720	823	399.30	deposit	2024-02-10
1721	1703	180.10	deposit	2024-05-04
1722	1328	324.20	withdrawal	2023-04-04
1723	36	226.10	deposit	2023-02-25
1724	1017	237.30	withdrawal	2023-04-23
1725	1034	181.70	deposit	2023-04-19
1726	280	213.20	withdrawal	2023-01-15
1727	1066	412.00	withdrawal	2023-06-12
1728	39	477.70	deposit	2024-03-08
1729	858	154.30	deposit	2023-11-07
1730	759	96.80	withdrawal	2023-01-21
1731	223	161.80	deposit	2023-04-20
1732	1288	427.70	deposit	2024-01-14
1733	1724	166.60	withdrawal	2024-05-28
1734	457	364.90	deposit	2024-01-03
1735	847	445.50	deposit	2023-04-19
1736	415	333.30	deposit	2023-07-13
1737	1098	124.90	deposit	2023-12-17
1738	1365	122.30	deposit	2023-06-20
1739	619	251.10	deposit	2024-02-07
1740	509	464.60	deposit	2024-04-02
1741	737	269.20	deposit	2023-07-01
1742	1751	259.40	deposit	2023-02-09
1743	1582	212.50	withdrawal	2023-06-06
1744	1105	160.50	withdrawal	2024-02-02
1745	1094	121.90	deposit	2024-05-28
1746	918	42.20	withdrawal	2024-02-28
1747	1522	341.60	deposit	2024-03-08
1748	399	69.20	withdrawal	2024-03-13
1749	1362	471.90	deposit	2023-10-22
1750	915	236.20	withdrawal	2024-02-11
1751	781	338.60	deposit	2023-04-28
1752	1485	483.90	deposit	2023-08-22
1753	1090	491.40	deposit	2024-02-04
1754	1515	171.60	withdrawal	2023-11-26
1755	1020	473.20	withdrawal	2023-07-30
1756	475	108.00	deposit	2024-04-18
1757	148	83.10	withdrawal	2023-10-24
1758	979	290.90	withdrawal	2023-03-16
1759	446	469.20	withdrawal	2023-01-09
1760	958	157.60	deposit	2023-09-11
1761	145	464.80	withdrawal	2023-09-07
1762	651	364.40	deposit	2023-11-01
1763	954	132.70	deposit	2023-09-12
1764	933	409.20	deposit	2023-11-18
1765	1479	276.90	deposit	2024-01-12
1766	1525	352.40	withdrawal	2023-12-06
1767	903	364.40	deposit	2024-04-27
1768	1493	241.50	deposit	2023-06-19
1769	942	299.20	withdrawal	2024-05-12
1770	1544	489.90	withdrawal	2024-02-22
1771	88	284.80	withdrawal	2024-01-06
1772	1152	215.80	withdrawal	2023-07-27
1773	311	201.30	deposit	2023-09-17
1774	970	419.80	deposit	2024-01-22
1775	1483	324.90	deposit	2023-11-12
1776	641	80.50	deposit	2023-08-14
1777	1592	139.90	withdrawal	2024-02-03
1778	551	386.80	withdrawal	2023-03-30
1779	1279	171.60	deposit	2024-01-12
1780	1070	286.80	deposit	2023-09-29
1781	601	492.30	deposit	2023-04-18
1782	1422	434.10	deposit	2023-07-22
1783	1523	50.80	deposit	2024-05-28
1784	69	48.00	deposit	2023-02-20
1785	1701	466.10	deposit	2024-03-16
1786	1205	192.60	withdrawal	2024-04-18
1787	1298	402.70	withdrawal	2023-08-15
1788	773	393.80	withdrawal	2023-04-11
1789	1655	163.10	withdrawal	2023-02-21
1790	27	367.00	deposit	2023-05-17
1791	1492	250.30	withdrawal	2023-07-15
1792	1429	213.20	deposit	2024-03-14
1793	119	36.10	withdrawal	2023-01-21
1794	342	246.80	deposit	2023-12-16
1795	308	53.90	withdrawal	2023-08-04
1796	200	68.20	deposit	2023-02-01
1797	541	277.60	deposit	2023-09-17
1798	551	242.40	deposit	2023-09-12
1799	1176	118.20	deposit	2023-07-15
1800	746	448.70	deposit	2024-05-11
1801	1379	151.50	withdrawal	2023-07-22
1802	1494	312.20	deposit	2024-03-20
1803	778	140.30	withdrawal	2023-12-15
1804	18	142.00	withdrawal	2023-11-11
1805	711	447.90	deposit	2023-09-28
1806	434	79.50	deposit	2023-03-05
1807	214	232.80	deposit	2024-03-11
1808	124	125.00	withdrawal	2023-07-02
1809	115	401.50	withdrawal	2023-07-05
1810	1759	205.00	withdrawal	2023-11-21
1811	771	497.10	deposit	2024-04-18
1812	599	359.70	deposit	2023-02-13
1813	853	105.40	deposit	2023-03-18
1814	1071	447.70	withdrawal	2024-03-20
1815	424	244.50	withdrawal	2023-03-11
1816	1136	140.20	deposit	2024-05-08
1817	103	380.40	withdrawal	2023-05-08
1818	639	488.60	withdrawal	2023-12-08
1819	839	470.90	deposit	2023-03-14
1820	666	421.60	deposit	2024-03-08
1821	1402	356.10	deposit	2023-10-12
1822	251	57.10	deposit	2023-09-25
1823	941	109.60	deposit	2023-08-17
1824	546	105.30	withdrawal	2023-07-13
1825	1279	321.90	deposit	2023-10-22
1826	367	246.50	withdrawal	2023-04-24
1827	247	355.80	withdrawal	2023-09-17
1828	1433	319.20	deposit	2023-01-01
1829	722	211.40	withdrawal	2023-07-01
1830	1033	227.70	deposit	2023-10-13
1831	1567	94.90	deposit	2024-05-10
1832	737	194.30	deposit	2023-08-14
1833	1493	263.70	deposit	2023-12-03
1834	405	238.50	withdrawal	2023-08-15
1835	1446	19.10	withdrawal	2023-08-11
1836	36	346.00	deposit	2024-03-11
1837	171	348.70	deposit	2023-06-14
1838	185	84.00	deposit	2024-02-03
1839	1336	476.00	withdrawal	2023-07-21
1840	1078	40.90	withdrawal	2023-05-02
1841	1688	229.90	deposit	2023-01-18
1842	698	367.10	deposit	2024-03-06
1843	586	104.10	withdrawal	2023-09-05
1844	1113	484.10	withdrawal	2023-12-09
1845	970	167.30	withdrawal	2023-01-14
1846	1128	159.40	withdrawal	2023-04-24
1847	188	452.70	withdrawal	2023-06-24
1848	1427	94.80	deposit	2024-03-12
1849	1029	410.80	deposit	2023-06-18
1850	33	485.70	withdrawal	2024-03-20
1851	1391	449.60	deposit	2023-07-20
1852	997	451.50	withdrawal	2023-04-15
1853	1362	352.40	deposit	2024-02-20
1854	1628	393.30	withdrawal	2024-05-10
1855	259	314.60	deposit	2023-07-25
1856	903	471.20	deposit	2024-02-04
1857	283	289.20	withdrawal	2023-04-27
1858	1708	81.30	withdrawal	2023-10-20
1859	667	119.70	deposit	2023-12-05
1860	1349	150.40	withdrawal	2023-06-15
1861	1576	449.40	deposit	2024-04-20
1862	1468	482.80	deposit	2023-09-18
1863	383	126.10	withdrawal	2024-04-28
1864	1147	221.10	deposit	2024-01-12
1865	303	323.20	withdrawal	2023-08-17
1866	1054	376.70	withdrawal	2023-09-25
1867	38	382.50	deposit	2023-12-23
1868	1546	256.90	withdrawal	2023-03-17
1869	849	341.60	deposit	2023-12-03
1870	1072	500.20	withdrawal	2024-01-25
1871	690	281.40	withdrawal	2024-05-11
1872	1599	397.30	withdrawal	2023-02-26
1873	577	439.10	withdrawal	2024-03-01
1874	1543	341.90	deposit	2023-06-12
1875	745	256.20	withdrawal	2023-09-05
1876	90	424.00	withdrawal	2024-05-05
1877	1280	251.10	withdrawal	2023-11-30
1878	1450	350.60	withdrawal	2023-05-14
1879	644	313.90	withdrawal	2024-01-16
1880	829	364.80	deposit	2023-01-12
1881	1223	318.60	withdrawal	2023-10-17
1882	230	360.70	deposit	2023-03-15
1883	1236	404.80	withdrawal	2023-01-17
1884	898	455.30	deposit	2023-06-15
1885	1627	387.80	deposit	2023-01-24
1886	1098	467.30	withdrawal	2023-11-12
1887	833	362.40	deposit	2024-02-05
1888	1676	355.90	deposit	2023-10-12
1889	1674	52.20	withdrawal	2023-04-07
1890	1118	359.40	deposit	2023-02-03
1891	989	372.60	withdrawal	2023-08-24
1892	343	22.40	deposit	2023-10-30
1893	81	324.80	deposit	2023-10-04
1894	1714	62.50	withdrawal	2024-04-16
1895	1543	236.90	withdrawal	2024-02-16
1896	808	333.20	deposit	2023-09-27
1897	587	485.90	deposit	2023-09-08
1898	180	35.70	withdrawal	2023-08-27
1899	421	372.00	deposit	2023-11-05
1900	1638	136.90	withdrawal	2023-07-19
1901	1283	493.70	deposit	2024-04-30
1902	1313	87.80	withdrawal	2023-04-01
1903	233	371.40	withdrawal	2023-05-12
1904	1065	299.40	deposit	2023-02-24
1905	340	492.20	deposit	2023-10-29
1906	1727	196.50	withdrawal	2024-04-05
1907	305	398.70	withdrawal	2024-05-21
1908	1117	67.30	deposit	2023-07-11
1909	190	165.90	withdrawal	2023-10-02
1910	1427	122.60	withdrawal	2024-05-01
1911	1051	314.60	withdrawal	2024-01-27
1912	8	397.10	withdrawal	2023-08-17
1913	717	123.40	withdrawal	2024-04-03
1914	419	154.20	withdrawal	2024-04-30
1915	529	271.90	withdrawal	2023-06-26
1916	1682	224.40	deposit	2023-11-01
1917	736	396.50	withdrawal	2023-04-17
1918	1246	439.20	withdrawal	2023-01-18
1919	892	358.80	withdrawal	2024-04-16
1920	915	470.70	withdrawal	2024-03-12
1921	28	442.30	withdrawal	2023-03-02
1922	1329	9.60	withdrawal	2024-01-18
1923	221	266.60	withdrawal	2023-10-25
1924	1545	133.40	deposit	2023-05-21
1925	1680	303.30	withdrawal	2024-01-09
1926	112	397.80	deposit	2024-03-28
1927	1159	350.40	withdrawal	2024-01-30
1928	1562	90.40	withdrawal	2023-04-06
1929	1433	483.10	withdrawal	2023-07-09
1930	1388	470.50	deposit	2023-02-07
1931	314	458.00	deposit	2024-05-17
1932	911	354.10	withdrawal	2024-03-19
1933	1286	262.30	withdrawal	2023-01-26
1934	1385	65.20	withdrawal	2023-10-07
1935	121	78.00	deposit	2023-06-04
1936	1657	322.30	deposit	2024-04-15
1937	227	222.20	withdrawal	2024-05-18
1938	19	428.10	deposit	2024-02-11
1939	598	457.90	deposit	2023-12-19
1940	1015	208.40	deposit	2024-05-17
1941	1575	238.60	withdrawal	2023-05-22
1942	1563	221.10	deposit	2024-05-29
1943	1269	406.10	withdrawal	2023-04-07
1944	1592	124.30	deposit	2023-10-05
1945	1171	475.50	withdrawal	2023-05-30
1946	526	425.90	deposit	2023-08-18
1947	1624	370.80	withdrawal	2023-12-12
1948	1195	166.70	withdrawal	2023-09-09
1949	1759	27.00	withdrawal	2023-09-16
1950	508	75.90	deposit	2024-05-09
1951	711	213.90	withdrawal	2023-07-09
1952	1038	298.60	deposit	2023-04-28
1953	1718	351.00	withdrawal	2024-01-22
1954	448	133.60	deposit	2023-09-11
1955	202	490.60	withdrawal	2023-10-13
1956	119	351.50	deposit	2023-06-21
1957	420	304.60	withdrawal	2023-12-29
1958	984	30.40	withdrawal	2023-04-11
1959	1163	350.00	withdrawal	2023-01-10
1960	1252	497.40	withdrawal	2023-01-23
1961	249	51.30	withdrawal	2023-06-09
1962	1511	318.10	deposit	2024-05-07
1963	66	252.80	withdrawal	2023-07-03
1964	1125	206.20	withdrawal	2023-04-26
1965	1072	233.80	deposit	2023-11-16
1966	1488	346.50	withdrawal	2024-04-18
1967	548	478.00	withdrawal	2023-05-30
1968	1311	29.90	deposit	2024-02-22
1969	703	397.00	deposit	2023-02-02
1970	69	476.50	withdrawal	2023-03-28
1971	1	142.70	deposit	2024-05-18
1972	561	392.70	deposit	2023-02-20
1973	695	293.50	deposit	2023-11-20
1974	77	253.60	withdrawal	2023-04-08
1975	1006	299.60	deposit	2023-07-28
1976	1401	195.40	deposit	2024-03-30
1977	542	321.20	withdrawal	2024-05-30
1978	597	485.70	deposit	2023-12-27
1979	1768	48.00	deposit	2024-03-06
1980	1101	387.60	deposit	2023-04-11
1981	987	134.50	withdrawal	2023-05-21
1982	1056	301.90	withdrawal	2023-07-19
1983	718	307.70	withdrawal	2023-03-06
1984	1204	366.10	withdrawal	2024-04-29
1985	1503	323.70	withdrawal	2023-08-24
1986	490	412.20	deposit	2023-04-27
1987	788	250.50	withdrawal	2024-05-07
1988	59	485.90	withdrawal	2024-01-25
1989	22	319.00	withdrawal	2023-10-30
1990	1312	500.70	withdrawal	2023-03-30
1991	514	62.90	deposit	2024-03-23
1992	788	251.80	deposit	2023-03-13
1993	382	356.50	deposit	2023-03-20
1994	976	199.30	deposit	2023-04-26
1995	862	489.10	deposit	2023-03-21
1996	769	300.10	deposit	2024-01-06
1997	1688	66.70	withdrawal	2023-04-11
1998	687	213.40	deposit	2024-02-29
1999	1122	13.10	deposit	2024-05-21
2000	1739	398.10	withdrawal	2023-12-17
2001	341	211.10	deposit	2023-09-18
2002	1699	434.90	deposit	2024-04-02
2003	242	222.10	withdrawal	2023-01-28
2004	1626	12.70	withdrawal	2023-04-15
2005	281	39.80	withdrawal	2024-04-25
2006	1607	389.80	withdrawal	2024-03-14
2007	39	490.60	deposit	2023-04-21
2008	1427	394.20	deposit	2023-06-29
2009	1341	386.20	deposit	2024-05-03
2010	1281	307.70	withdrawal	2023-07-26
2011	363	334.10	deposit	2024-02-20
2012	1363	207.20	deposit	2024-04-12
2013	790	195.30	deposit	2023-11-02
2014	739	328.20	withdrawal	2023-05-28
2015	1073	162.90	deposit	2024-05-21
2016	697	178.10	deposit	2023-02-24
2017	715	473.30	deposit	2023-04-08
2018	1240	288.50	deposit	2023-10-19
2019	1795	240.20	deposit	2023-05-21
2020	1664	129.90	withdrawal	2024-03-10
2021	1713	70.20	deposit	2023-07-17
2022	241	465.40	withdrawal	2023-07-20
2023	1468	75.40	withdrawal	2023-03-07
2024	192	416.70	withdrawal	2023-08-23
2025	651	21.10	withdrawal	2024-02-07
2026	205	269.20	withdrawal	2023-12-17
2027	348	336.90	withdrawal	2023-02-05
2028	221	460.30	withdrawal	2024-01-03
2029	1318	153.70	deposit	2024-01-27
2030	238	204.60	deposit	2023-05-10
2031	630	404.20	deposit	2023-12-04
2032	668	243.00	withdrawal	2024-02-26
2033	969	40.30	withdrawal	2023-06-24
2034	567	446.10	withdrawal	2023-04-02
2035	593	16.60	deposit	2024-05-26
2036	66	29.80	withdrawal	2023-02-07
2037	1479	155.50	withdrawal	2024-01-26
2038	1456	237.90	withdrawal	2023-10-01
2039	754	284.10	withdrawal	2023-04-13
2040	535	71.90	withdrawal	2024-01-21
2041	1237	50.30	withdrawal	2023-11-27
2042	613	218.20	withdrawal	2024-03-20
2043	847	367.40	withdrawal	2023-01-06
2044	1622	11.80	deposit	2023-11-23
2045	842	360.40	withdrawal	2024-03-26
2046	1794	248.00	deposit	2023-11-24
2047	1260	341.40	withdrawal	2023-12-15
2048	137	73.00	withdrawal	2023-09-29
2049	248	272.00	withdrawal	2023-07-26
2050	1308	448.10	deposit	2024-01-24
2051	414	468.10	withdrawal	2023-01-21
2052	266	166.30	deposit	2023-09-08
2053	1050	256.70	withdrawal	2023-02-20
2054	981	439.70	withdrawal	2023-12-08
2055	162	96.90	withdrawal	2024-03-19
2056	11	237.60	deposit	2023-08-01
2057	1506	482.70	withdrawal	2023-12-09
2058	1106	466.00	deposit	2024-02-07
2059	1392	479.40	deposit	2024-05-10
2060	777	269.20	withdrawal	2023-12-11
2061	1321	162.70	withdrawal	2023-08-28
2062	647	123.30	deposit	2024-05-10
2063	261	469.80	deposit	2023-04-13
2064	1434	247.30	deposit	2024-03-19
2065	270	14.00	deposit	2023-10-31
2066	325	153.90	withdrawal	2023-01-28
2067	1247	82.50	withdrawal	2023-10-02
2068	1040	186.60	withdrawal	2023-05-28
2069	16	133.50	deposit	2024-03-19
2070	238	232.60	deposit	2023-07-21
2071	1506	413.90	deposit	2024-03-11
2072	899	27.10	deposit	2023-05-10
2073	821	281.70	deposit	2023-05-25
2074	497	371.90	deposit	2024-04-05
2075	1005	40.80	withdrawal	2024-05-15
2076	490	246.20	deposit	2024-03-25
2077	1646	378.60	deposit	2024-02-07
2078	548	272.90	withdrawal	2024-05-21
2079	1458	182.20	withdrawal	2023-09-07
2080	1538	374.90	withdrawal	2023-10-05
2081	643	91.10	withdrawal	2023-08-10
2082	374	355.40	withdrawal	2023-08-24
2083	425	267.50	deposit	2024-04-10
2084	605	268.20	deposit	2024-01-21
2085	729	400.00	deposit	2024-02-04
2086	1295	122.20	deposit	2023-06-11
2087	908	341.20	withdrawal	2024-01-27
2088	1050	497.90	deposit	2023-05-15
2089	585	126.20	deposit	2023-09-25
2090	634	232.20	withdrawal	2023-12-08
2091	1395	204.30	deposit	2024-02-16
2092	1616	41.20	withdrawal	2023-08-25
2093	1247	51.30	deposit	2023-04-27
2094	1187	407.10	withdrawal	2023-08-23
2095	188	234.20	withdrawal	2023-03-22
2096	867	295.80	deposit	2024-03-04
2097	1485	15.70	withdrawal	2024-05-11
2098	22	430.50	deposit	2023-03-13
2099	601	283.10	withdrawal	2024-05-12
2100	1216	376.10	deposit	2023-12-30
2101	464	352.00	deposit	2023-06-23
2102	1355	412.70	withdrawal	2023-02-05
2103	451	299.20	withdrawal	2024-05-08
2104	195	457.00	withdrawal	2024-04-24
2105	1064	32.90	withdrawal	2023-08-16
2106	1014	476.70	deposit	2024-05-18
2107	1141	36.70	withdrawal	2023-10-21
2108	737	443.00	deposit	2023-12-08
2109	168	144.20	withdrawal	2023-10-08
2110	659	433.60	deposit	2023-10-24
2111	540	224.80	withdrawal	2023-04-29
2112	257	124.30	deposit	2023-10-01
2113	1676	24.00	deposit	2023-08-15
2114	920	444.50	withdrawal	2023-07-06
2115	731	73.20	withdrawal	2024-03-02
2116	87	121.30	withdrawal	2023-09-09
2117	523	469.70	withdrawal	2024-02-05
2118	766	294.30	withdrawal	2024-03-09
2119	1789	154.20	withdrawal	2023-05-12
2120	1294	300.60	deposit	2023-02-10
2121	206	475.30	deposit	2023-02-14
2122	1540	376.20	deposit	2023-12-08
2123	1053	248.70	withdrawal	2024-03-22
2124	1369	93.90	withdrawal	2023-04-01
2125	1458	119.00	withdrawal	2023-06-12
2126	1794	128.80	deposit	2023-07-10
2127	1137	379.80	deposit	2023-04-06
2128	158	95.10	deposit	2024-02-13
2129	1665	331.40	withdrawal	2023-12-01
2130	469	242.40	deposit	2023-07-05
2131	842	116.80	withdrawal	2023-01-26
2132	1160	190.30	deposit	2023-12-01
2133	1373	310.00	deposit	2024-01-04
2134	906	48.40	deposit	2024-03-11
2135	538	222.70	withdrawal	2023-11-29
2136	1349	27.00	deposit	2023-01-13
2137	85	104.70	withdrawal	2023-09-12
2138	316	103.10	withdrawal	2024-04-20
2139	1033	377.30	withdrawal	2023-05-27
2140	817	69.90	withdrawal	2024-01-17
2141	1651	242.90	withdrawal	2024-02-17
2142	608	246.90	deposit	2023-12-22
2143	926	80.30	deposit	2023-08-13
2144	1248	6.90	withdrawal	2024-03-09
2145	44	150.60	withdrawal	2024-04-30
2146	560	357.00	withdrawal	2023-04-08
2147	1507	228.10	deposit	2023-03-02
2148	962	49.80	withdrawal	2023-04-09
2149	1386	141.20	withdrawal	2024-04-20
2150	1304	441.60	deposit	2023-03-16
2151	1175	242.40	deposit	2024-04-27
2152	1448	114.70	deposit	2024-03-13
2153	1447	310.60	withdrawal	2023-08-02
2154	1220	326.80	deposit	2023-06-22
2155	303	190.20	withdrawal	2023-12-11
2156	1745	125.80	withdrawal	2023-08-08
2157	1043	78.30	withdrawal	2023-11-04
2158	1006	198.80	deposit	2023-10-12
2159	942	280.90	withdrawal	2023-09-09
2160	1022	473.20	withdrawal	2023-09-15
2161	748	11.10	withdrawal	2024-01-24
2162	506	281.80	deposit	2024-02-11
2163	226	194.10	deposit	2023-04-28
2164	512	215.00	withdrawal	2024-04-13
2165	740	318.10	withdrawal	2023-03-08
2166	509	185.20	deposit	2024-05-13
2167	1621	316.20	withdrawal	2023-09-23
2168	1617	34.80	deposit	2023-06-04
2169	890	347.80	withdrawal	2023-04-25
2170	1583	97.10	withdrawal	2024-03-19
2171	844	223.20	withdrawal	2023-09-06
2172	833	275.60	withdrawal	2024-05-22
2173	1023	480.20	deposit	2024-03-06
2174	1056	35.30	withdrawal	2023-08-17
2175	1282	99.80	deposit	2024-02-01
2176	1162	208.90	withdrawal	2024-02-17
2177	1521	18.30	withdrawal	2023-06-09
2178	778	197.80	deposit	2024-04-16
2179	1551	500.50	deposit	2023-02-12
2180	1195	18.00	deposit	2023-06-13
2181	992	492.90	deposit	2024-03-24
2182	1696	454.30	withdrawal	2024-01-24
2183	894	136.00	withdrawal	2024-02-03
2184	804	377.20	deposit	2024-04-07
2185	1694	299.80	deposit	2024-05-29
2186	650	29.40	deposit	2023-05-22
2187	650	141.30	withdrawal	2023-09-11
2188	1511	85.30	deposit	2024-04-19
2189	939	26.30	deposit	2023-07-09
2190	615	302.90	withdrawal	2023-07-02
2191	1032	417.70	deposit	2024-01-11
2192	474	375.60	withdrawal	2023-12-09
2193	503	55.10	deposit	2023-11-17
2194	1431	115.90	deposit	2023-10-12
2195	1502	351.30	deposit	2024-02-20
2196	1227	443.40	withdrawal	2024-02-01
2197	975	20.20	deposit	2023-04-30
2198	757	488.20	deposit	2024-03-18
2199	1133	261.80	deposit	2024-03-19
2200	1623	72.60	deposit	2024-01-08
2201	302	106.60	deposit	2023-12-04
2202	122	480.90	deposit	2023-09-11
2203	372	61.60	deposit	2023-09-19
2204	1265	195.40	withdrawal	2024-03-18
2205	631	293.50	deposit	2023-04-26
2206	851	406.20	withdrawal	2023-12-28
2207	27	251.30	deposit	2023-09-17
2208	1494	266.80	withdrawal	2023-08-25
2209	816	71.40	withdrawal	2024-04-01
2210	436	5.80	deposit	2023-09-14
2211	577	26.70	deposit	2023-12-31
2212	57	108.40	withdrawal	2023-12-06
2213	202	346.70	withdrawal	2023-04-17
2214	403	91.90	deposit	2023-06-05
2215	285	377.20	withdrawal	2023-05-11
2216	375	306.40	withdrawal	2024-04-20
2217	1299	324.60	deposit	2023-07-19
2218	1605	393.00	withdrawal	2023-10-16
2219	1115	238.00	withdrawal	2023-09-22
2220	192	31.50	withdrawal	2023-03-01
2221	851	72.00	deposit	2023-12-10
2222	1107	369.00	deposit	2024-02-07
2223	575	110.70	withdrawal	2023-03-23
2224	1640	416.20	deposit	2024-01-18
2225	917	323.30	deposit	2024-01-21
2226	467	334.50	deposit	2023-10-13
2227	721	279.20	withdrawal	2023-03-30
2228	1252	111.90	withdrawal	2023-12-07
2229	1227	359.40	deposit	2023-06-24
2230	955	261.50	withdrawal	2024-05-14
2231	172	457.70	withdrawal	2023-12-08
2232	289	385.60	deposit	2023-01-16
2233	1742	291.90	deposit	2023-03-18
2234	891	223.10	withdrawal	2023-08-05
2235	573	95.40	deposit	2023-09-02
2236	1463	134.10	withdrawal	2023-07-02
2237	1630	138.50	deposit	2023-02-03
2238	1246	182.30	deposit	2023-03-26
2239	696	360.30	withdrawal	2023-04-22
2240	240	238.90	withdrawal	2023-12-23
2241	1275	175.00	withdrawal	2023-03-04
2242	230	395.20	deposit	2023-09-02
2243	950	306.90	withdrawal	2023-11-18
2244	123	107.40	withdrawal	2023-01-06
2245	359	132.40	withdrawal	2023-01-28
2246	226	419.70	deposit	2023-04-03
2247	728	390.00	withdrawal	2024-03-08
2248	890	311.70	withdrawal	2023-03-09
2249	1745	180.50	withdrawal	2023-09-28
2250	1760	121.80	deposit	2023-08-25
2251	1253	455.80	deposit	2023-06-25
2252	732	451.30	deposit	2024-01-28
2253	788	233.00	deposit	2023-03-17
2254	1645	422.20	withdrawal	2023-04-26
2255	1167	98.70	withdrawal	2023-11-28
2256	759	441.40	withdrawal	2023-10-22
2257	672	114.20	deposit	2023-03-31
2258	642	45.90	withdrawal	2023-07-08
2259	1177	234.30	withdrawal	2023-05-01
2260	1747	157.50	deposit	2023-03-06
2261	1522	450.80	deposit	2024-03-25
2262	788	314.60	deposit	2023-07-08
2263	1465	122.30	deposit	2023-09-06
2264	567	201.50	deposit	2023-03-28
2265	123	199.50	withdrawal	2023-07-28
2266	1559	161.30	deposit	2023-08-23
2267	175	450.90	withdrawal	2023-08-06
2268	197	118.30	withdrawal	2023-03-10
2269	509	426.20	withdrawal	2024-03-23
2270	1110	233.60	deposit	2023-06-03
2271	1128	293.20	withdrawal	2023-10-09
2272	364	289.90	deposit	2023-08-02
2273	605	57.70	deposit	2024-03-26
2274	1388	467.80	deposit	2023-12-13
2275	389	80.30	deposit	2023-10-17
2276	1266	279.10	deposit	2023-06-28
2277	461	268.40	withdrawal	2023-11-30
2278	1649	384.00	deposit	2024-02-23
2279	809	229.70	withdrawal	2023-09-02
2280	980	301.70	deposit	2023-07-29
2281	765	138.80	deposit	2023-06-19
2282	1516	69.00	withdrawal	2023-03-04
2283	1415	391.90	deposit	2023-06-01
2284	186	95.10	deposit	2023-08-23
2285	1320	163.70	deposit	2023-03-03
2286	1120	132.70	deposit	2023-07-21
2287	422	130.10	withdrawal	2023-05-27
2288	1762	78.60	deposit	2023-01-01
2289	213	208.00	withdrawal	2023-10-17
2290	906	34.20	deposit	2023-05-09
2291	498	230.20	deposit	2023-07-04
2292	1380	431.80	deposit	2023-01-04
2293	189	414.70	deposit	2023-07-17
2294	1548	460.60	withdrawal	2024-01-03
2295	430	211.90	withdrawal	2024-01-24
2296	843	437.50	withdrawal	2024-01-18
2297	1151	154.10	deposit	2024-03-15
2298	843	228.10	deposit	2023-10-17
2299	1510	104.00	deposit	2023-12-17
2300	1413	404.60	withdrawal	2024-02-24
2301	874	340.20	withdrawal	2024-03-08
2302	1184	112.50	deposit	2023-12-14
2303	195	404.70	withdrawal	2023-01-17
2304	967	330.50	deposit	2023-09-06
2305	1416	446.90	deposit	2023-05-31
2306	20	332.70	deposit	2024-01-26
2307	820	260.50	withdrawal	2023-08-13
2308	202	64.50	deposit	2023-03-23
2309	235	262.50	withdrawal	2023-08-30
2310	1472	123.50	withdrawal	2023-04-09
2311	1698	473.20	deposit	2023-01-10
2312	1271	430.00	withdrawal	2023-09-15
2313	409	435.60	deposit	2024-02-07
2314	1302	452.00	withdrawal	2023-07-21
2315	573	53.60	withdrawal	2023-07-14
2316	1010	459.50	deposit	2023-01-21
2317	1046	369.80	deposit	2023-07-16
2318	1261	26.60	deposit	2023-05-02
2319	106	105.30	deposit	2023-08-18
2320	1432	339.80	withdrawal	2023-10-07
2321	635	291.10	deposit	2024-04-28
2322	56	333.80	deposit	2023-10-20
2323	1316	441.40	withdrawal	2023-07-12
2324	887	19.70	deposit	2023-01-19
2325	743	253.90	deposit	2024-03-09
2326	1511	7.10	withdrawal	2023-04-07
2327	531	408.60	withdrawal	2023-03-22
2328	1451	113.90	deposit	2023-06-18
2329	27	364.10	withdrawal	2023-10-11
2330	909	482.70	withdrawal	2024-03-17
2331	1313	386.80	deposit	2023-03-04
2332	1048	226.80	deposit	2023-08-07
2333	1243	286.20	deposit	2024-04-27
2334	635	27.00	deposit	2023-04-20
2335	1508	135.80	withdrawal	2024-04-15
2336	357	404.30	deposit	2023-12-03
2337	1473	277.50	withdrawal	2023-12-12
2338	285	63.20	deposit	2023-03-10
2339	892	61.40	withdrawal	2023-01-04
2340	1596	496.40	withdrawal	2024-03-08
2341	1568	95.90	withdrawal	2023-09-29
2342	1033	448.90	withdrawal	2023-10-13
2343	1334	437.40	deposit	2023-07-05
2344	1446	58.10	deposit	2023-05-05
2345	44	73.90	withdrawal	2023-02-22
2346	577	133.40	deposit	2023-10-28
2347	1123	133.70	withdrawal	2024-01-28
2348	211	389.10	deposit	2023-11-13
2349	91	212.90	deposit	2023-03-09
2350	1617	43.50	deposit	2023-02-09
2351	776	483.50	withdrawal	2024-02-24
2352	236	130.00	deposit	2023-03-23
2353	826	408.50	withdrawal	2023-02-07
2354	454	403.30	withdrawal	2023-01-04
2355	1177	439.60	deposit	2023-01-23
2356	1682	136.40	withdrawal	2023-11-22
2357	1461	21.90	withdrawal	2024-01-09
2358	209	498.80	withdrawal	2023-10-10
2359	811	330.10	withdrawal	2024-02-18
2360	200	448.80	deposit	2024-04-13
2361	1219	470.10	withdrawal	2024-04-14
2362	516	128.70	deposit	2024-03-06
2363	67	272.70	withdrawal	2023-07-08
2364	1028	85.00	deposit	2023-01-15
2365	380	76.30	deposit	2023-02-27
2366	691	188.00	deposit	2023-04-07
2367	1113	274.50	deposit	2023-03-17
2368	705	435.00	deposit	2023-02-28
2369	921	261.80	withdrawal	2024-03-06
2370	1200	126.70	withdrawal	2023-05-01
2371	1458	19.70	withdrawal	2024-05-09
2372	673	31.70	withdrawal	2023-05-30
2373	1258	463.90	deposit	2023-04-27
2374	1575	108.60	deposit	2023-04-17
2375	397	435.70	deposit	2024-03-29
2376	1442	326.60	withdrawal	2024-03-28
2377	916	235.30	withdrawal	2024-05-05
2378	252	323.10	withdrawal	2023-12-05
2379	1151	29.60	deposit	2023-08-12
2380	1058	495.00	deposit	2024-03-16
2381	1764	15.10	deposit	2024-04-29
2382	436	149.00	withdrawal	2024-03-31
2383	1383	107.00	deposit	2023-08-24
2384	1516	302.90	deposit	2023-08-31
2385	1781	236.50	deposit	2024-01-21
2386	1364	104.60	deposit	2023-09-14
2387	1521	144.30	deposit	2024-04-20
2388	1632	254.00	withdrawal	2023-06-04
2389	1511	266.80	withdrawal	2023-02-02
2390	1316	109.00	deposit	2023-06-05
2391	1203	265.40	deposit	2024-04-01
2392	1165	286.20	withdrawal	2024-03-05
2393	745	434.30	deposit	2023-09-09
2394	193	433.90	deposit	2024-05-27
2395	640	458.00	withdrawal	2024-03-30
2396	603	75.80	deposit	2023-01-01
2397	165	201.50	deposit	2023-10-30
2398	1134	261.80	withdrawal	2023-10-08
2399	123	33.30	withdrawal	2023-05-28
2400	1451	189.70	deposit	2024-03-22
2401	897	250.60	withdrawal	2023-02-07
2402	263	59.10	withdrawal	2023-08-27
2403	1110	274.60	deposit	2024-05-12
2404	1450	451.90	withdrawal	2023-05-21
2405	356	440.30	withdrawal	2023-01-28
2406	1365	220.70	withdrawal	2024-01-17
2407	992	489.70	withdrawal	2023-07-24
2408	817	246.90	withdrawal	2024-03-29
2409	1052	100.50	withdrawal	2023-09-28
2410	740	196.60	withdrawal	2023-10-14
2411	1360	205.70	deposit	2023-06-04
2412	527	395.10	withdrawal	2024-01-27
2413	1133	308.90	deposit	2024-03-24
2414	818	168.40	withdrawal	2023-04-03
2415	765	317.10	withdrawal	2024-02-03
2416	918	116.40	withdrawal	2023-08-08
2417	580	221.20	withdrawal	2023-06-21
2418	946	23.60	withdrawal	2024-01-31
2419	1665	284.10	deposit	2024-02-07
2420	1617	403.70	withdrawal	2024-04-15
2421	620	398.10	withdrawal	2023-02-16
2422	1127	82.90	deposit	2023-08-13
2423	164	145.90	deposit	2023-07-03
2424	466	298.50	withdrawal	2024-03-05
2425	109	241.80	withdrawal	2023-03-22
2426	283	168.20	deposit	2023-12-26
2427	429	471.10	withdrawal	2024-01-17
2428	1123	130.90	deposit	2024-04-22
2429	39	185.30	withdrawal	2023-02-28
2430	597	490.60	deposit	2023-02-27
2431	1661	133.70	withdrawal	2023-12-14
2432	942	255.70	deposit	2023-03-10
2433	185	474.30	withdrawal	2023-08-16
2434	734	165.40	withdrawal	2023-08-28
2435	256	161.70	deposit	2023-09-15
2436	573	103.30	withdrawal	2024-01-13
2437	1289	270.90	withdrawal	2023-08-25
2438	472	157.10	deposit	2023-05-30
2439	1794	363.30	deposit	2023-07-02
2440	540	493.60	deposit	2023-04-25
2441	1508	92.20	deposit	2023-06-22
2442	689	436.40	deposit	2024-05-15
2443	327	340.70	withdrawal	2023-12-20
2444	450	99.60	withdrawal	2023-09-23
2445	138	184.40	deposit	2024-04-06
2446	922	378.40	deposit	2023-09-09
2447	1482	109.50	withdrawal	2024-03-19
2448	342	68.60	withdrawal	2024-03-23
2449	1134	50.50	withdrawal	2023-07-23
2450	1673	340.20	deposit	2024-01-10
2451	1210	407.20	withdrawal	2023-10-05
2452	867	311.10	deposit	2023-06-29
2453	672	325.80	withdrawal	2023-03-12
2454	400	276.60	deposit	2023-01-17
2455	204	341.00	withdrawal	2024-03-17
2456	1776	481.70	deposit	2023-02-27
2457	1564	168.60	withdrawal	2024-04-15
2458	212	39.90	deposit	2024-05-07
2459	1618	195.40	deposit	2024-03-03
2460	1679	457.50	deposit	2023-04-12
2461	1794	29.70	withdrawal	2023-08-28
2462	93	192.30	withdrawal	2023-03-22
2463	704	95.20	deposit	2023-06-11
2464	1459	442.00	withdrawal	2024-04-10
2465	95	483.70	deposit	2024-01-02
2466	1368	327.10	deposit	2024-03-30
2467	1486	172.10	withdrawal	2024-05-26
2468	385	76.20	withdrawal	2023-12-03
2469	1505	100.20	withdrawal	2023-08-17
2470	1435	158.70	withdrawal	2024-01-12
2471	804	222.70	withdrawal	2023-03-07
2472	749	208.70	deposit	2023-12-30
2473	913	172.90	withdrawal	2023-12-04
2474	194	350.70	withdrawal	2023-02-28
2475	153	47.90	withdrawal	2023-08-10
2476	1231	170.90	deposit	2023-06-11
2477	127	428.80	deposit	2023-01-03
2478	1002	77.40	deposit	2023-06-11
2479	357	286.30	withdrawal	2023-05-28
2480	151	187.80	withdrawal	2024-02-09
2481	1660	195.00	withdrawal	2023-06-03
2482	678	495.70	withdrawal	2024-02-27
2483	83	364.20	deposit	2023-06-23
2484	1006	329.60	withdrawal	2024-05-17
2485	514	331.80	withdrawal	2024-03-01
2486	108	157.80	deposit	2024-05-13
2487	494	188.60	deposit	2023-11-19
2488	1729	48.70	deposit	2023-03-08
2489	1755	147.20	deposit	2024-02-09
2490	90	157.50	withdrawal	2023-01-22
2491	815	295.40	deposit	2023-03-02
2492	600	177.60	withdrawal	2023-10-03
2493	471	163.80	withdrawal	2023-11-29
2494	403	497.90	deposit	2023-11-01
2495	717	252.20	withdrawal	2024-01-09
2496	761	129.00	deposit	2024-02-14
2497	1109	309.30	deposit	2023-10-25
2498	734	241.00	withdrawal	2024-01-31
2499	492	264.00	withdrawal	2023-11-23
2500	1544	108.20	deposit	2023-09-15
2501	1585	340.10	withdrawal	2023-10-31
2502	108	413.90	withdrawal	2023-11-07
2503	748	205.60	withdrawal	2024-01-13
2504	1540	346.70	withdrawal	2023-10-12
2505	62	298.00	deposit	2024-04-02
2506	1626	149.40	deposit	2024-04-10
2507	1241	285.00	withdrawal	2023-10-20
2508	912	462.30	withdrawal	2023-08-28
2509	852	143.80	deposit	2023-12-16
2510	666	13.40	withdrawal	2024-03-11
2511	597	134.80	deposit	2024-02-24
2512	1612	58.70	deposit	2023-01-27
2513	511	129.60	deposit	2023-01-29
2514	1639	435.90	withdrawal	2023-04-18
2515	819	262.10	withdrawal	2023-03-01
2516	1169	128.80	deposit	2023-07-03
2517	219	133.10	withdrawal	2023-02-22
2518	1210	242.10	deposit	2023-01-22
2519	536	116.80	withdrawal	2023-05-05
2520	1319	454.10	deposit	2024-01-25
2521	949	60.60	deposit	2024-03-30
2522	1403	439.80	deposit	2023-06-11
2523	1609	460.80	withdrawal	2024-03-26
2524	1534	157.60	deposit	2024-04-09
2525	1402	206.90	deposit	2023-08-17
2526	1457	320.80	withdrawal	2023-11-14
2527	1493	448.40	withdrawal	2023-05-19
2528	1681	262.40	deposit	2023-01-29
2529	979	6.50	deposit	2023-12-08
2530	1027	5.30	deposit	2023-05-31
2531	960	43.60	deposit	2023-02-06
2532	136	297.40	withdrawal	2023-03-26
2533	1722	175.00	withdrawal	2023-03-12
2534	1733	80.60	withdrawal	2023-01-08
2535	389	225.80	deposit	2024-01-12
2536	383	344.80	deposit	2024-04-27
2537	556	405.10	withdrawal	2024-04-26
2538	590	435.30	withdrawal	2023-12-11
2539	165	224.20	deposit	2024-01-26
2540	1225	295.00	deposit	2023-09-30
2541	1190	102.70	withdrawal	2023-09-05
2542	1791	441.10	deposit	2023-02-01
2543	660	338.90	withdrawal	2023-08-20
2544	1020	130.40	deposit	2023-05-05
2545	586	27.10	deposit	2023-01-06
2546	187	434.20	withdrawal	2024-02-06
2547	1507	369.10	withdrawal	2023-12-02
2548	1517	220.90	deposit	2023-12-17
2549	1289	38.50	withdrawal	2023-09-08
2550	1725	161.90	withdrawal	2023-06-10
2551	1446	289.50	deposit	2023-03-16
2552	176	155.30	withdrawal	2023-06-04
2553	507	109.50	deposit	2023-06-02
2554	228	125.30	withdrawal	2023-12-15
2555	1567	200.90	withdrawal	2024-01-16
2556	408	389.80	withdrawal	2024-05-31
2557	528	114.30	deposit	2024-03-21
2558	873	156.80	deposit	2023-02-05
2559	1562	177.40	withdrawal	2024-05-06
2560	1514	54.90	deposit	2024-02-11
2561	701	376.60	withdrawal	2023-05-02
2562	738	285.70	deposit	2023-10-02
2563	46	229.90	withdrawal	2023-12-25
2564	36	34.70	deposit	2023-05-19
2565	522	265.60	deposit	2024-03-04
2566	1252	444.10	withdrawal	2024-01-15
2567	208	469.30	deposit	2023-08-08
2568	1533	435.30	withdrawal	2024-05-04
2569	564	62.30	withdrawal	2023-12-29
2570	1726	13.00	deposit	2023-07-27
2571	1758	148.00	deposit	2024-02-07
2572	1587	214.30	deposit	2023-02-06
2573	436	496.40	deposit	2023-12-20
2574	1463	227.10	deposit	2023-12-13
2575	646	230.10	deposit	2023-04-08
2576	864	346.50	deposit	2023-05-13
2577	319	304.30	withdrawal	2023-04-21
2578	1263	323.10	withdrawal	2024-02-24
2579	459	395.10	deposit	2024-03-25
2580	581	103.70	deposit	2024-01-20
2581	251	189.10	deposit	2024-05-02
2582	339	84.00	withdrawal	2023-12-23
2583	1336	196.90	withdrawal	2023-04-07
2584	1017	177.10	deposit	2023-12-10
2585	1366	485.10	withdrawal	2024-04-22
2586	122	351.70	withdrawal	2024-03-06
2587	1318	318.10	deposit	2023-07-30
2588	1161	152.80	deposit	2024-02-16
2589	428	421.20	deposit	2024-03-14
2590	463	450.20	withdrawal	2023-01-27
2591	1694	315.10	withdrawal	2023-02-26
2592	1037	180.30	withdrawal	2023-05-06
2593	1518	487.50	deposit	2023-10-22
2594	1137	225.00	deposit	2024-03-06
2595	274	389.70	withdrawal	2024-02-05
2596	1752	336.50	withdrawal	2023-06-28
2597	223	457.10	withdrawal	2023-01-10
2598	564	119.80	deposit	2023-08-27
2599	1602	477.00	withdrawal	2024-01-05
2600	87	260.90	withdrawal	2024-02-01
2601	1232	459.80	deposit	2023-03-07
2602	573	106.50	withdrawal	2023-01-04
2603	1256	163.00	deposit	2023-01-13
2604	430	14.10	withdrawal	2023-11-23
2605	835	487.90	withdrawal	2023-08-24
2606	546	39.00	deposit	2024-04-01
2607	985	108.00	deposit	2023-04-26
2608	604	478.80	withdrawal	2024-01-26
2609	771	146.80	withdrawal	2023-05-01
2610	304	301.30	withdrawal	2024-01-14
2611	471	135.20	deposit	2024-01-20
2612	471	12.50	deposit	2024-03-08
2613	1214	287.00	deposit	2024-02-22
2614	1472	392.30	withdrawal	2023-06-29
2615	499	271.00	withdrawal	2024-03-26
2616	834	240.90	deposit	2023-08-10
2617	1231	291.60	withdrawal	2023-05-01
2618	381	164.60	deposit	2023-11-19
2619	996	274.90	deposit	2023-05-08
2620	1792	412.50	withdrawal	2024-03-16
2621	1354	95.10	withdrawal	2023-06-13
2622	1551	12.30	deposit	2023-06-02
2623	187	450.20	withdrawal	2023-12-06
2624	281	10.20	withdrawal	2023-06-16
2625	452	179.30	withdrawal	2023-03-04
2626	644	66.90	deposit	2024-02-02
2627	439	24.30	withdrawal	2023-09-16
2628	345	490.30	withdrawal	2024-03-30
2629	44	417.10	deposit	2023-09-21
2630	340	419.40	withdrawal	2023-08-01
2631	1487	233.50	withdrawal	2023-08-30
2632	187	188.30	deposit	2023-05-15
2633	33	261.50	deposit	2023-10-22
2634	1560	428.10	withdrawal	2023-01-17
2635	1214	453.80	withdrawal	2023-10-21
2636	130	448.40	withdrawal	2023-05-28
2637	991	263.60	withdrawal	2024-02-19
2638	567	23.30	withdrawal	2023-05-25
2639	1355	47.10	deposit	2023-06-04
2640	788	187.20	deposit	2023-03-25
2641	805	364.80	deposit	2024-03-12
2642	497	307.90	deposit	2023-12-24
2643	838	80.40	deposit	2024-03-09
2644	130	300.30	deposit	2023-07-10
2645	27	490.20	withdrawal	2023-02-16
2646	1163	199.40	deposit	2023-04-11
2647	687	314.90	deposit	2023-11-27
2648	1666	330.40	withdrawal	2024-02-10
2649	160	197.90	withdrawal	2023-06-05
2650	491	82.20	deposit	2024-02-18
2651	921	45.50	withdrawal	2023-11-29
2652	1409	455.40	withdrawal	2023-09-03
2653	1572	481.60	deposit	2023-08-31
2654	435	70.20	withdrawal	2023-08-06
2655	1128	148.20	deposit	2023-07-14
2656	817	378.40	deposit	2024-01-26
2657	1374	45.00	deposit	2023-11-30
2658	430	22.60	deposit	2023-01-02
2659	1603	118.90	deposit	2023-12-29
2660	234	190.20	withdrawal	2023-08-27
2661	507	146.00	deposit	2023-05-26
2662	1650	120.40	deposit	2023-09-02
2663	1628	261.90	deposit	2023-09-27
2664	298	283.30	deposit	2024-03-24
2665	1615	321.20	deposit	2023-05-27
2666	1437	355.30	deposit	2024-03-05
2667	736	352.90	deposit	2024-03-03
2668	811	301.90	withdrawal	2023-03-16
2669	1289	38.80	withdrawal	2023-07-10
2670	1734	13.80	deposit	2023-09-01
2671	328	248.90	deposit	2023-12-12
2672	1700	355.90	deposit	2023-07-10
2673	1383	421.40	deposit	2023-05-30
2674	1483	163.10	withdrawal	2023-08-24
2675	587	222.20	deposit	2024-05-10
2676	1565	314.40	withdrawal	2023-07-21
2677	835	28.30	withdrawal	2023-10-17
2678	1366	353.60	withdrawal	2023-10-27
2679	1050	68.20	deposit	2023-03-04
2680	1191	428.70	deposit	2023-08-24
2681	169	229.80	withdrawal	2024-02-29
2682	1413	102.30	withdrawal	2023-10-29
2683	776	65.00	withdrawal	2023-05-05
2684	1048	116.60	deposit	2024-04-03
2685	749	358.30	withdrawal	2023-06-20
2686	453	159.00	deposit	2023-12-21
2687	1728	397.80	deposit	2023-06-23
2688	1615	120.40	deposit	2023-07-14
2689	497	95.80	withdrawal	2023-01-30
2690	113	415.70	deposit	2023-12-22
2691	1570	399.10	deposit	2023-08-11
2692	1055	194.80	deposit	2023-02-23
2693	1634	398.10	withdrawal	2024-01-25
2694	689	156.80	deposit	2023-07-11
2695	275	164.30	withdrawal	2023-05-14
2696	1218	169.30	deposit	2023-07-02
2697	1361	365.90	deposit	2024-01-28
2698	133	88.80	deposit	2023-12-07
2699	171	481.00	withdrawal	2023-01-30
2700	1723	121.80	deposit	2023-08-28
2701	948	398.70	withdrawal	2024-03-24
2702	1354	327.40	deposit	2023-01-07
2703	937	83.80	withdrawal	2023-02-06
2704	1118	277.70	deposit	2024-01-03
2705	704	55.60	withdrawal	2024-04-06
2706	958	288.00	withdrawal	2024-02-01
2707	1255	113.10	deposit	2023-11-10
2708	1091	374.80	withdrawal	2023-04-30
2709	913	158.60	withdrawal	2023-01-17
2710	121	53.60	withdrawal	2023-12-12
2711	1350	397.30	deposit	2023-01-31
2712	1026	46.30	deposit	2024-05-09
2713	1315	334.30	deposit	2023-05-17
2714	1500	259.40	withdrawal	2023-10-27
2715	1508	166.80	withdrawal	2023-08-06
2716	1492	471.00	deposit	2024-05-26
2717	773	195.20	withdrawal	2023-10-01
2718	644	498.70	withdrawal	2023-08-17
2719	592	372.90	deposit	2023-05-25
2720	1074	55.30	withdrawal	2024-01-26
2721	1705	190.50	deposit	2023-08-26
2722	643	241.10	deposit	2023-03-22
2723	461	95.40	deposit	2024-03-02
2724	786	304.50	withdrawal	2023-01-21
2725	1174	347.20	deposit	2023-04-13
2726	1275	269.20	withdrawal	2023-02-16
2727	1301	376.00	deposit	2024-02-01
2728	1426	56.10	withdrawal	2024-03-09
2729	1350	409.20	withdrawal	2023-01-13
2730	1400	23.40	withdrawal	2023-06-22
2731	712	391.30	withdrawal	2023-02-16
2732	1061	348.70	withdrawal	2024-02-17
2733	932	450.10	withdrawal	2024-05-12
2734	1736	289.80	deposit	2023-01-16
2735	613	214.70	withdrawal	2024-03-01
2736	45	115.80	deposit	2024-04-06
2737	1560	162.20	withdrawal	2023-05-01
2738	1037	27.80	withdrawal	2023-09-24
2739	1558	161.50	withdrawal	2024-01-18
2740	1580	389.40	deposit	2023-01-31
2741	304	390.00	deposit	2023-03-18
2742	1595	143.80	deposit	2023-10-12
2743	820	322.20	withdrawal	2023-05-21
2744	459	128.20	deposit	2024-05-25
2745	1665	106.50	deposit	2023-04-24
2746	1764	51.30	withdrawal	2024-05-31
2747	1321	371.90	withdrawal	2023-06-24
2748	110	227.10	deposit	2023-07-09
2749	1019	427.60	deposit	2024-05-18
2750	1714	465.00	deposit	2024-05-29
2751	314	72.80	withdrawal	2023-06-30
2752	1457	280.30	withdrawal	2023-04-26
2753	412	246.20	withdrawal	2023-09-07
2754	230	35.80	deposit	2023-07-24
2755	164	189.50	deposit	2023-01-11
2756	365	391.50	withdrawal	2024-02-21
2757	1410	427.90	withdrawal	2024-02-05
2758	1298	49.40	deposit	2024-04-30
2759	545	318.40	withdrawal	2023-02-09
2760	1745	148.20	deposit	2024-03-10
2761	1155	59.30	deposit	2023-07-13
2762	892	169.70	withdrawal	2023-10-06
2763	1045	371.40	deposit	2023-06-11
2764	1800	263.90	deposit	2023-12-05
2765	174	163.60	deposit	2024-05-18
2766	206	121.10	deposit	2023-04-12
2767	1497	494.80	withdrawal	2023-10-14
2768	1600	148.60	withdrawal	2023-12-12
2769	1708	477.60	withdrawal	2024-05-04
2770	1327	442.30	withdrawal	2023-05-01
2771	515	81.30	deposit	2024-04-03
2772	1155	416.00	withdrawal	2023-05-24
2773	1759	210.70	deposit	2023-07-21
2774	316	180.70	deposit	2024-05-06
2775	286	348.30	withdrawal	2024-03-02
2776	42	171.60	withdrawal	2023-07-25
2777	797	272.20	withdrawal	2023-01-26
2778	651	204.20	deposit	2024-04-15
2779	1751	73.60	withdrawal	2023-02-11
2780	556	478.40	withdrawal	2023-12-19
2781	1627	16.90	withdrawal	2024-05-21
2782	692	458.50	withdrawal	2023-09-05
2783	45	12.40	deposit	2024-01-09
2784	1574	452.40	withdrawal	2023-12-20
2785	33	184.90	withdrawal	2024-02-26
2786	1382	450.80	withdrawal	2024-01-20
2787	770	403.80	withdrawal	2024-05-16
2788	922	284.70	withdrawal	2023-02-06
2789	1718	325.30	deposit	2023-09-23
2790	1751	50.10	deposit	2023-08-27
2791	578	483.60	deposit	2023-01-18
2792	717	343.70	deposit	2023-02-20
2793	428	53.00	withdrawal	2023-11-25
2794	98	259.10	deposit	2024-01-21
2795	1428	243.60	withdrawal	2023-06-24
2796	1464	51.20	deposit	2023-10-17
2797	118	244.70	withdrawal	2024-01-20
2798	1795	392.60	deposit	2023-12-29
2799	1494	187.50	withdrawal	2023-11-09
2800	1227	362.00	withdrawal	2024-05-30
2801	851	66.50	deposit	2024-03-22
2802	1482	346.80	withdrawal	2023-11-17
2803	1477	173.90	deposit	2024-03-02
2804	1257	409.90	deposit	2023-04-07
2805	21	400.50	deposit	2023-09-08
2806	489	237.10	withdrawal	2023-11-08
2807	501	409.10	deposit	2023-01-04
2808	461	138.90	withdrawal	2023-11-10
2809	1240	84.70	deposit	2023-11-02
2810	68	308.50	deposit	2024-04-05
2811	1053	218.40	withdrawal	2023-07-02
2812	1150	429.00	withdrawal	2023-11-16
2813	678	333.10	withdrawal	2023-03-13
2814	708	29.00	deposit	2023-02-04
2815	357	497.80	withdrawal	2023-01-24
2816	551	274.10	deposit	2023-10-09
2817	1606	214.90	deposit	2023-04-15
2818	1495	445.40	withdrawal	2023-09-06
2819	620	85.60	withdrawal	2023-06-12
2820	192	424.00	deposit	2024-01-13
2821	511	190.90	deposit	2023-10-07
2822	680	481.60	withdrawal	2023-03-16
2823	1734	491.60	withdrawal	2023-07-25
2824	618	146.30	deposit	2023-04-09
2825	1447	271.60	withdrawal	2023-04-21
2826	103	87.60	withdrawal	2023-11-23
2827	1723	177.70	deposit	2023-09-19
2828	1460	246.60	withdrawal	2023-04-18
2829	1184	158.70	deposit	2023-03-17
2830	205	332.60	deposit	2024-05-05
2831	731	43.50	deposit	2024-01-11
2832	1416	19.50	deposit	2023-03-30
2833	1480	401.60	deposit	2023-02-25
2834	64	119.20	withdrawal	2023-05-03
2835	395	24.80	deposit	2024-05-12
2836	392	167.20	withdrawal	2023-10-03
2837	1561	475.20	withdrawal	2023-06-04
2838	489	117.90	deposit	2023-02-21
2839	955	323.00	withdrawal	2024-04-24
2840	696	243.00	deposit	2023-10-20
2841	618	335.50	deposit	2023-09-01
2842	867	343.70	withdrawal	2024-01-24
2843	529	84.60	deposit	2023-09-15
2844	655	219.10	deposit	2023-01-15
2845	3	395.70	withdrawal	2023-05-07
2846	1017	107.30	withdrawal	2023-01-09
2847	165	205.40	deposit	2024-03-10
2848	180	395.50	deposit	2023-08-04
2849	967	453.30	withdrawal	2024-05-29
2850	1537	224.40	withdrawal	2023-04-13
2851	1041	351.80	withdrawal	2023-11-03
2852	734	470.90	deposit	2023-12-18
2853	1117	101.90	deposit	2023-04-03
2854	327	141.00	deposit	2023-11-29
2855	278	121.70	deposit	2024-04-07
2856	728	250.50	withdrawal	2023-02-27
2857	868	360.70	withdrawal	2024-04-24
2858	1154	48.80	withdrawal	2023-02-17
2859	1137	495.60	deposit	2023-08-03
2860	1427	482.90	withdrawal	2023-04-29
2861	491	367.70	deposit	2024-05-19
2862	952	263.00	withdrawal	2023-09-08
2863	440	13.60	deposit	2024-05-11
2864	313	418.20	deposit	2023-08-16
2865	286	96.20	withdrawal	2023-12-31
2866	1621	313.50	deposit	2023-05-03
2867	144	168.80	deposit	2023-10-04
2868	1776	422.80	withdrawal	2023-05-16
2869	1212	161.00	deposit	2023-12-10
2870	384	88.00	deposit	2023-07-28
2871	1741	144.00	withdrawal	2023-05-13
2872	139	372.80	withdrawal	2023-04-18
2873	1737	25.30	deposit	2024-01-27
2874	1511	451.40	withdrawal	2023-06-13
2875	859	495.50	deposit	2023-03-06
2876	1387	411.80	deposit	2024-01-30
2877	1458	47.80	deposit	2023-04-11
2878	442	283.70	deposit	2023-10-02
2879	1099	117.60	withdrawal	2024-04-13
2880	705	463.00	withdrawal	2023-11-16
2881	1409	432.60	withdrawal	2024-04-11
2882	221	433.20	deposit	2023-03-18
2883	393	376.70	withdrawal	2023-09-21
2884	215	476.90	deposit	2023-01-31
2885	1230	301.50	withdrawal	2023-02-25
2886	395	500.50	withdrawal	2023-12-28
2887	836	202.40	deposit	2024-02-07
2888	1051	285.60	deposit	2023-05-29
2889	1784	160.10	deposit	2023-06-09
2890	1458	195.10	withdrawal	2023-10-17
2891	1301	154.70	withdrawal	2024-03-23
2892	100	392.80	withdrawal	2023-11-25
2893	1126	348.10	deposit	2024-03-01
2894	306	251.40	withdrawal	2024-03-05
2895	65	372.30	deposit	2024-04-30
2896	1069	321.70	withdrawal	2024-05-01
2897	937	50.70	deposit	2023-07-29
2898	1398	233.70	deposit	2023-05-29
2899	1285	500.00	withdrawal	2024-03-16
2900	1065	202.90	withdrawal	2023-07-31
2901	1022	44.80	deposit	2023-02-01
2902	786	149.70	withdrawal	2023-01-06
2903	1369	467.90	withdrawal	2023-03-16
2904	1044	197.80	deposit	2023-05-15
2905	78	446.80	withdrawal	2023-08-18
2906	617	169.00	withdrawal	2023-12-08
2907	931	473.00	deposit	2023-06-20
2908	678	476.00	withdrawal	2023-05-17
2909	232	100.20	withdrawal	2024-02-14
2910	639	433.30	withdrawal	2024-02-14
2911	874	399.20	withdrawal	2024-02-20
2912	1681	8.20	deposit	2023-09-25
2913	421	396.30	deposit	2023-01-08
2914	1318	498.40	deposit	2023-09-07
2915	1467	266.70	deposit	2024-05-04
2916	981	108.10	deposit	2023-11-17
2917	28	337.80	deposit	2024-05-12
2918	758	468.30	deposit	2023-12-25
2919	26	454.10	withdrawal	2023-08-25
2920	153	54.90	deposit	2023-05-28
2921	1543	214.90	withdrawal	2023-06-16
2922	1532	94.20	withdrawal	2023-10-07
2923	1006	212.80	deposit	2023-05-13
2924	156	282.80	deposit	2023-09-27
2925	1503	94.00	withdrawal	2024-03-20
2926	67	390.30	deposit	2023-04-06
2927	910	73.10	withdrawal	2023-12-02
2928	1780	267.70	withdrawal	2023-03-18
2929	559	470.20	deposit	2024-01-09
2930	1461	386.60	deposit	2023-05-21
2931	481	120.60	deposit	2024-02-11
2932	433	76.60	withdrawal	2023-11-19
2933	1647	188.40	withdrawal	2023-11-22
2934	650	55.50	deposit	2024-03-20
2935	865	312.30	withdrawal	2023-04-20
2936	1025	297.90	deposit	2024-05-01
2937	333	65.10	deposit	2023-05-16
2938	797	76.10	withdrawal	2024-01-30
2939	1077	160.80	deposit	2023-06-04
2940	861	14.00	deposit	2024-05-06
2941	1181	475.30	deposit	2023-11-08
2942	1564	128.50	withdrawal	2024-02-27
2943	760	133.30	deposit	2024-05-24
2944	1531	32.10	deposit	2023-06-21
2945	12	357.50	deposit	2023-11-05
2946	701	5.10	deposit	2023-10-21
2947	1688	415.80	withdrawal	2024-05-20
2948	538	164.40	deposit	2023-01-07
2949	814	96.30	deposit	2024-04-03
2950	1634	331.90	deposit	2023-12-28
2951	1450	355.90	deposit	2023-11-24
2952	1064	95.60	deposit	2024-03-10
2953	301	136.40	deposit	2023-09-06
2954	1481	299.00	withdrawal	2023-07-09
2955	1329	326.40	deposit	2023-06-26
2956	1253	226.70	deposit	2024-04-14
2957	718	71.50	withdrawal	2024-01-06
2958	1236	493.20	withdrawal	2024-01-05
2959	644	95.80	withdrawal	2024-01-07
2960	854	365.70	deposit	2023-07-07
2961	1473	406.80	deposit	2023-06-29
2962	103	167.20	withdrawal	2023-03-10
2963	877	337.10	deposit	2024-05-03
2964	1562	62.10	withdrawal	2023-04-05
2965	1777	286.10	deposit	2023-05-26
2966	1286	212.20	deposit	2023-04-29
2967	400	95.40	withdrawal	2023-01-08
2968	1433	111.10	deposit	2023-11-25
2969	715	50.90	withdrawal	2023-04-26
2970	1630	9.20	withdrawal	2024-03-02
2971	292	210.30	withdrawal	2023-11-10
2972	149	417.90	withdrawal	2023-07-24
2973	1601	49.70	withdrawal	2023-12-12
2974	1481	436.50	deposit	2024-02-17
2975	853	221.50	deposit	2023-02-19
2976	1091	130.00	withdrawal	2023-09-11
2977	377	166.70	withdrawal	2023-07-27
2978	95	94.00	withdrawal	2023-04-13
2979	1582	328.90	deposit	2023-04-26
2980	1594	437.00	deposit	2023-06-03
2981	175	235.60	deposit	2023-08-15
2982	1720	150.00	withdrawal	2024-03-05
2983	1339	158.10	deposit	2024-03-27
2984	1187	436.80	deposit	2024-03-19
2985	840	421.30	deposit	2023-09-29
2986	208	449.30	deposit	2024-05-20
2987	1715	24.00	deposit	2023-10-13
2988	560	329.70	deposit	2023-05-09
2989	664	213.30	withdrawal	2024-01-03
2990	42	267.60	withdrawal	2023-06-21
2991	754	183.20	deposit	2024-01-17
2992	1534	169.60	deposit	2024-04-02
2993	1103	498.70	deposit	2024-03-18
2994	1474	272.10	deposit	2023-06-05
2995	1738	222.00	deposit	2023-07-24
2996	1449	70.30	withdrawal	2023-11-09
2997	1265	201.40	withdrawal	2023-07-17
2998	1460	136.80	deposit	2023-05-06
2999	165	172.40	deposit	2024-04-15
3000	424	174.40	withdrawal	2023-05-27
3001	1380	17.80	deposit	2023-05-20
3002	306	336.90	deposit	2024-02-04
3003	1351	491.30	deposit	2024-04-13
3004	864	459.70	deposit	2023-06-24
3005	141	261.60	withdrawal	2023-05-13
3006	1274	379.50	deposit	2023-12-12
3007	1012	9.20	deposit	2023-07-10
3008	1120	500.10	withdrawal	2023-09-28
3009	729	137.30	withdrawal	2023-02-02
3010	876	212.00	withdrawal	2023-08-10
3011	1065	431.30	deposit	2023-11-30
3012	299	204.50	deposit	2023-07-17
3013	1157	75.10	withdrawal	2023-01-06
3014	228	107.40	withdrawal	2024-04-10
3015	375	196.10	deposit	2024-03-28
3016	1714	401.60	withdrawal	2023-03-20
3017	494	486.50	deposit	2024-05-15
3018	808	140.40	deposit	2024-02-28
3019	700	407.40	withdrawal	2023-07-28
3020	1129	224.70	withdrawal	2023-09-03
3021	1595	30.80	withdrawal	2024-01-16
3022	495	128.20	withdrawal	2024-03-16
3023	890	481.00	withdrawal	2024-02-19
3024	1320	9.10	deposit	2024-05-04
3025	1358	241.10	withdrawal	2023-08-24
3026	427	267.70	withdrawal	2023-03-15
3027	893	127.90	deposit	2023-02-28
3028	1732	224.50	deposit	2023-05-16
3029	659	198.50	deposit	2023-09-30
3030	1421	201.20	deposit	2024-02-11
3031	523	258.70	withdrawal	2024-03-27
3032	917	403.00	deposit	2024-02-23
3033	1161	223.30	withdrawal	2023-02-10
3034	327	453.10	withdrawal	2023-05-01
3035	1359	448.70	withdrawal	2023-03-29
3036	15	184.60	deposit	2023-09-12
3037	983	29.70	withdrawal	2024-03-06
3038	1690	373.70	withdrawal	2023-01-31
3039	1458	89.40	deposit	2023-10-11
3040	1161	344.60	withdrawal	2023-04-18
3041	225	92.40	withdrawal	2023-02-20
3042	1338	18.60	deposit	2023-08-18
3043	1515	13.70	deposit	2023-05-21
3044	1041	283.50	withdrawal	2024-02-09
3045	898	325.70	deposit	2024-04-15
3046	961	446.20	withdrawal	2023-08-15
3047	1089	341.60	withdrawal	2023-02-09
3048	1521	469.80	deposit	2024-02-08
3049	1107	289.00	withdrawal	2024-04-05
3050	1050	266.70	withdrawal	2023-03-24
3051	750	212.50	deposit	2023-06-25
3052	1023	11.70	withdrawal	2023-02-23
3053	797	76.60	withdrawal	2024-02-25
3054	189	217.00	withdrawal	2023-04-11
3055	856	267.70	deposit	2024-01-17
3056	1306	415.80	deposit	2024-01-11
3057	872	485.80	withdrawal	2023-11-24
3058	107	362.20	withdrawal	2023-05-18
3059	996	492.80	withdrawal	2024-01-13
3060	837	277.70	withdrawal	2023-06-05
3061	1034	71.30	withdrawal	2023-03-16
3062	1135	246.10	deposit	2023-09-03
3063	568	60.60	withdrawal	2024-04-06
3064	953	205.60	withdrawal	2023-09-11
3065	1437	482.70	withdrawal	2023-03-09
3066	282	113.90	deposit	2024-01-11
3067	649	405.00	withdrawal	2024-01-01
3068	645	460.80	deposit	2024-05-21
3069	1140	103.60	deposit	2024-03-10
3070	1747	428.80	deposit	2023-05-13
3071	341	378.30	deposit	2023-11-11
3072	165	47.20	deposit	2023-02-07
3073	1092	202.10	deposit	2023-04-23
3074	809	266.50	withdrawal	2023-01-28
3075	1108	422.90	deposit	2023-01-07
3076	74	362.70	deposit	2024-01-11
3077	867	97.80	deposit	2023-05-05
3078	1602	23.60	withdrawal	2023-09-10
3079	232	462.30	deposit	2023-07-11
3080	127	381.40	deposit	2023-04-14
3081	1514	412.90	withdrawal	2024-04-22
3082	768	296.30	withdrawal	2024-05-14
3083	314	121.50	withdrawal	2024-04-03
3084	1609	460.50	withdrawal	2023-07-09
3085	770	121.30	withdrawal	2024-05-25
3086	1532	460.00	withdrawal	2023-01-11
3087	189	347.70	withdrawal	2024-05-17
3088	721	371.10	withdrawal	2024-05-02
3089	1631	481.90	deposit	2023-12-07
3090	87	489.50	deposit	2023-09-20
3091	1135	407.40	withdrawal	2023-08-28
3092	223	162.80	withdrawal	2023-09-13
3093	940	426.00	deposit	2023-09-13
3094	1336	394.00	deposit	2024-02-08
3095	744	404.50	deposit	2024-04-16
3096	1761	155.90	withdrawal	2023-12-08
3097	1092	458.90	withdrawal	2024-02-05
3098	243	301.10	withdrawal	2023-05-31
3099	1304	280.00	deposit	2023-12-11
3100	923	433.40	deposit	2024-04-04
3330	821	77.50	deposit	2024-02-19
3101	718	330.80	withdrawal	2023-11-29
3102	1023	426.40	withdrawal	2024-03-05
3103	1108	397.50	deposit	2023-01-06
3104	710	460.90	deposit	2023-03-04
3105	1333	379.60	withdrawal	2023-09-24
3106	115	333.60	deposit	2024-05-14
3107	1405	226.30	withdrawal	2024-04-07
3108	417	473.50	withdrawal	2023-03-12
3109	1410	134.90	withdrawal	2023-04-17
3110	71	103.80	withdrawal	2023-04-10
3111	286	231.40	withdrawal	2023-08-31
3112	1560	241.10	withdrawal	2023-02-08
3113	380	311.10	deposit	2023-02-15
3114	1526	132.80	withdrawal	2023-04-11
3115	1187	217.10	deposit	2023-06-24
3116	1778	301.50	deposit	2023-04-20
3117	635	325.10	withdrawal	2023-09-04
3118	150	195.80	withdrawal	2024-04-18
3119	441	167.10	deposit	2023-02-23
3120	981	500.00	withdrawal	2023-10-20
3121	819	320.70	deposit	2023-04-23
3122	411	359.00	withdrawal	2023-02-12
3123	756	423.50	withdrawal	2023-01-26
3124	451	93.50	withdrawal	2024-02-04
3125	1535	231.10	withdrawal	2023-11-09
3126	1799	246.70	withdrawal	2023-07-29
3127	1203	45.80	deposit	2023-08-14
3128	1467	484.70	deposit	2023-07-01
3129	1561	281.80	withdrawal	2023-05-03
3130	942	367.10	withdrawal	2024-04-21
3131	1371	78.10	deposit	2024-01-09
3132	309	327.60	withdrawal	2023-01-15
3133	1575	191.90	deposit	2024-01-27
3134	1527	105.00	deposit	2024-03-22
3135	1079	352.30	deposit	2023-04-22
3136	1657	231.60	withdrawal	2023-05-21
3137	76	209.40	deposit	2024-03-09
3138	954	217.60	withdrawal	2023-04-29
3139	1502	265.60	withdrawal	2023-10-14
3140	1167	138.90	deposit	2023-03-10
3141	786	77.50	withdrawal	2023-05-12
3142	1758	30.50	withdrawal	2023-11-14
3143	392	362.80	deposit	2023-12-11
3144	59	132.90	deposit	2023-08-09
3145	327	260.30	withdrawal	2023-09-19
3146	92	428.30	withdrawal	2024-03-21
3147	235	445.30	deposit	2024-03-13
3148	1339	121.70	withdrawal	2023-01-09
3149	700	317.10	deposit	2024-04-13
3150	298	152.90	withdrawal	2024-05-20
3151	282	137.40	deposit	2023-03-26
3152	186	10.60	withdrawal	2023-06-09
3153	1416	127.70	deposit	2023-07-23
3154	978	23.80	withdrawal	2024-04-23
3155	154	231.50	withdrawal	2023-06-26
3156	961	157.70	withdrawal	2024-03-30
3157	67	202.10	withdrawal	2024-03-15
3158	364	63.10	withdrawal	2023-10-26
3159	489	200.20	withdrawal	2023-10-06
3160	264	416.20	withdrawal	2023-11-30
3161	972	154.90	withdrawal	2023-09-03
3162	1576	164.40	deposit	2024-02-29
3163	1335	173.00	withdrawal	2024-01-10
3164	286	246.70	deposit	2023-03-28
3165	938	160.60	deposit	2023-11-13
3166	1623	491.40	withdrawal	2023-07-20
3167	376	16.70	withdrawal	2023-04-04
3168	6	486.30	withdrawal	2023-07-15
3169	988	42.90	deposit	2023-05-13
3170	1037	88.00	withdrawal	2023-07-22
3171	825	342.60	withdrawal	2024-04-09
3172	302	99.80	withdrawal	2023-12-30
3173	1050	86.60	withdrawal	2024-05-02
3174	450	442.20	withdrawal	2024-02-08
3175	1775	102.10	deposit	2023-04-06
3176	130	112.60	deposit	2024-04-29
3177	1127	13.70	deposit	2023-02-28
3178	757	155.40	deposit	2024-01-20
3179	848	179.10	deposit	2023-08-30
3180	1129	179.10	deposit	2024-02-23
3181	940	134.80	withdrawal	2023-10-22
3182	1284	172.60	withdrawal	2024-01-20
3183	677	200.70	withdrawal	2023-07-04
3184	525	407.30	withdrawal	2024-03-24
3185	847	83.20	withdrawal	2023-02-14
3186	64	272.90	withdrawal	2024-02-27
3187	209	293.40	withdrawal	2023-09-15
3188	968	484.40	deposit	2024-04-19
3189	1520	13.70	withdrawal	2023-03-01
3190	1276	431.20	deposit	2024-03-29
3191	262	40.50	deposit	2024-03-22
3192	954	100.90	withdrawal	2023-02-23
3193	1118	50.80	deposit	2024-05-14
3194	1013	436.70	deposit	2023-10-26
3195	228	36.10	withdrawal	2023-08-14
3196	44	139.30	deposit	2024-01-14
3197	1190	69.90	withdrawal	2023-07-05
3198	1451	231.50	withdrawal	2023-08-17
3199	495	426.70	deposit	2024-01-06
3200	217	308.10	withdrawal	2023-10-30
3201	340	178.60	deposit	2023-08-20
3202	1193	45.40	withdrawal	2023-02-28
3203	754	8.90	withdrawal	2023-09-29
3204	1595	374.40	deposit	2023-11-24
3205	1165	215.20	withdrawal	2024-01-24
3206	1620	197.00	withdrawal	2024-01-25
3207	55	159.80	deposit	2024-04-16
3208	536	70.90	withdrawal	2023-09-07
3209	74	375.60	withdrawal	2023-10-01
3210	1112	358.20	deposit	2023-07-01
3211	184	222.70	deposit	2023-04-08
3212	1351	43.50	deposit	2024-02-03
3213	169	181.90	deposit	2024-05-28
3214	1381	21.50	withdrawal	2024-01-16
3215	132	497.90	withdrawal	2024-04-09
3216	1237	366.10	deposit	2023-06-20
3217	1336	144.60	withdrawal	2023-10-02
3218	216	60.70	deposit	2023-11-21
3219	493	329.20	deposit	2023-01-04
3220	405	118.30	deposit	2023-03-14
3221	1796	70.80	deposit	2024-01-01
3222	135	332.00	withdrawal	2023-02-19
3223	1146	475.50	deposit	2024-05-30
3224	540	152.50	withdrawal	2023-09-04
3225	1603	216.80	deposit	2024-02-05
3226	1583	311.10	deposit	2023-12-18
3227	1214	417.20	deposit	2024-02-13
3228	1772	269.10	deposit	2023-04-17
3229	776	172.10	withdrawal	2023-10-30
3230	1613	47.50	withdrawal	2023-02-07
3231	1026	244.00	withdrawal	2024-03-13
3232	714	30.10	withdrawal	2024-05-19
3233	345	209.60	withdrawal	2023-04-02
3234	1692	311.20	withdrawal	2023-01-18
3235	1456	169.90	withdrawal	2023-11-25
3236	792	444.60	deposit	2023-09-27
3237	111	299.50	withdrawal	2023-05-13
3238	1210	222.00	deposit	2023-05-22
3239	1603	106.40	deposit	2023-06-18
3240	677	105.70	withdrawal	2024-04-09
3241	1363	47.80	deposit	2023-10-06
3242	343	255.40	deposit	2023-05-28
3243	1214	187.90	withdrawal	2023-06-30
3244	1053	317.10	withdrawal	2023-12-24
3245	1575	228.70	withdrawal	2023-04-12
3246	363	393.00	withdrawal	2023-01-29
3247	1072	380.10	deposit	2023-06-07
3248	781	356.90	deposit	2023-10-25
3249	736	234.90	withdrawal	2024-04-12
3250	245	330.50	deposit	2023-10-26
3251	1287	215.90	withdrawal	2023-12-20
3252	186	306.30	withdrawal	2024-04-13
3253	193	40.30	withdrawal	2023-09-22
3254	400	211.70	withdrawal	2024-02-21
3255	597	214.30	deposit	2023-12-15
3256	457	283.60	deposit	2024-03-07
3257	1547	73.10	deposit	2023-11-04
3258	1126	278.30	withdrawal	2024-01-10
3259	1512	163.60	deposit	2023-02-25
3260	376	241.70	withdrawal	2023-04-15
3261	967	69.30	withdrawal	2023-03-30
3262	959	41.40	deposit	2023-03-01
3263	42	473.60	withdrawal	2023-01-30
3264	105	137.60	withdrawal	2023-08-12
3265	254	259.70	deposit	2023-07-03
3266	169	350.10	withdrawal	2023-11-03
3267	1231	335.40	deposit	2023-08-27
3268	1154	283.50	deposit	2024-01-06
3269	1631	354.20	deposit	2023-02-10
3270	1242	141.90	deposit	2023-06-01
3271	433	374.90	deposit	2023-09-09
3272	1504	244.30	deposit	2023-07-31
3273	1417	273.30	withdrawal	2024-01-30
3274	1299	17.40	withdrawal	2024-02-27
3275	1181	412.70	deposit	2023-09-04
3276	1020	187.80	deposit	2023-02-11
3277	1653	340.00	withdrawal	2023-09-13
3278	176	342.90	deposit	2023-08-16
3279	1453	95.90	deposit	2023-06-21
3280	921	120.30	withdrawal	2023-12-22
3281	1783	238.00	deposit	2023-12-04
3282	70	157.50	deposit	2024-03-01
3283	450	400.30	withdrawal	2023-03-24
3284	729	302.30	withdrawal	2024-01-11
3285	196	158.40	withdrawal	2024-04-16
3286	1221	490.00	deposit	2024-02-12
3287	1183	185.70	deposit	2023-04-14
3288	799	262.90	withdrawal	2023-04-30
3289	72	334.30	deposit	2023-04-19
3290	365	345.80	deposit	2024-01-03
3291	163	234.60	deposit	2023-06-02
3292	1530	81.00	deposit	2023-01-20
3293	714	188.30	withdrawal	2023-12-19
3294	1548	273.60	withdrawal	2024-02-12
3295	1597	246.90	withdrawal	2024-04-15
3296	856	245.70	deposit	2023-07-15
3297	818	148.40	deposit	2023-10-24
3298	1472	36.60	deposit	2023-07-27
3299	1214	226.90	withdrawal	2023-02-05
3300	472	112.60	deposit	2024-01-10
3301	628	284.00	deposit	2023-05-31
3302	740	333.10	deposit	2023-07-24
3303	1283	53.20	deposit	2024-04-10
3304	1429	364.70	withdrawal	2023-04-19
3305	1250	149.30	deposit	2024-01-20
3306	480	169.30	withdrawal	2023-03-21
3307	1309	152.00	deposit	2024-05-08
3308	1111	18.90	deposit	2023-04-01
3309	1408	166.40	deposit	2023-07-02
3310	87	142.50	withdrawal	2023-11-07
3311	1500	268.50	deposit	2024-01-22
3312	1214	357.10	withdrawal	2023-08-14
3313	189	402.10	withdrawal	2023-03-15
3314	1039	486.20	deposit	2023-08-07
3315	1474	29.40	deposit	2023-02-16
3316	440	234.40	withdrawal	2023-07-10
3317	1197	324.00	deposit	2024-03-19
3318	1042	430.70	deposit	2024-01-07
3319	944	185.70	deposit	2024-02-20
3320	31	391.20	deposit	2023-11-15
3321	481	295.80	withdrawal	2023-04-11
3322	1759	213.80	withdrawal	2023-05-09
3323	1302	287.60	deposit	2023-12-05
3324	1197	23.10	deposit	2023-11-24
3325	524	221.40	deposit	2024-03-19
3326	1376	255.00	deposit	2023-10-23
3327	182	203.80	deposit	2023-04-27
3328	501	27.60	deposit	2023-04-30
3329	1532	190.10	deposit	2023-03-04
3331	1603	278.60	withdrawal	2024-05-11
3332	1128	406.00	deposit	2023-09-08
3333	413	67.80	deposit	2024-01-30
3334	1186	187.40	deposit	2024-03-28
3335	429	465.60	deposit	2024-05-28
3336	17	12.10	withdrawal	2024-04-15
3337	629	401.80	deposit	2023-06-12
3338	1276	297.20	deposit	2023-10-16
3339	560	110.70	withdrawal	2024-04-06
3340	1458	410.60	withdrawal	2023-01-27
3341	956	257.80	withdrawal	2023-08-04
3342	1073	287.20	withdrawal	2024-05-07
3343	408	262.70	deposit	2024-03-20
3344	249	176.90	deposit	2024-05-11
3345	699	495.40	withdrawal	2024-03-16
3346	1533	479.10	withdrawal	2023-05-03
3347	1121	130.30	withdrawal	2023-06-12
3348	126	279.30	deposit	2024-01-11
3349	265	402.50	deposit	2023-11-03
3350	457	64.60	withdrawal	2024-05-08
3351	151	344.50	withdrawal	2023-03-23
3352	1573	22.10	withdrawal	2023-11-28
3353	1344	465.20	withdrawal	2023-02-21
3354	1254	86.10	deposit	2023-04-26
3355	1286	236.20	withdrawal	2023-08-24
3356	1708	183.20	deposit	2024-02-10
3357	976	222.40	withdrawal	2023-01-22
3358	929	359.00	deposit	2024-05-14
3359	1799	466.80	withdrawal	2024-04-09
3360	663	418.20	deposit	2023-12-17
3361	1211	120.60	withdrawal	2023-01-05
3362	1569	374.40	deposit	2023-01-24
3363	935	492.80	deposit	2023-02-16
3364	1337	294.70	withdrawal	2023-09-11
3365	900	133.80	withdrawal	2024-02-14
3366	628	398.90	deposit	2023-02-25
3367	1411	498.80	deposit	2024-02-28
3368	1643	358.40	withdrawal	2023-04-01
3369	1316	148.50	deposit	2024-05-13
3370	987	423.80	deposit	2024-01-13
3371	521	70.00	deposit	2023-08-14
3372	168	103.60	withdrawal	2023-07-25
3373	1360	61.40	deposit	2024-05-02
3374	413	458.10	deposit	2024-05-07
3375	391	385.40	withdrawal	2023-12-19
3376	1187	282.90	deposit	2023-05-12
3377	1710	474.70	deposit	2023-02-23
3378	1012	485.90	deposit	2023-07-21
3379	856	70.90	withdrawal	2023-02-10
3380	440	459.40	deposit	2023-11-13
3381	1257	235.20	deposit	2023-07-28
3382	987	424.40	withdrawal	2023-02-25
3383	1476	407.50	withdrawal	2024-04-25
3384	1325	12.80	withdrawal	2023-11-26
3385	671	221.80	withdrawal	2023-12-17
3386	444	253.70	deposit	2023-05-12
3387	1301	463.30	withdrawal	2023-03-20
3388	575	346.70	withdrawal	2023-03-31
3389	500	288.70	withdrawal	2023-06-07
3390	117	104.50	deposit	2023-07-29
3391	934	298.40	deposit	2023-12-29
3392	690	343.90	withdrawal	2024-01-28
3393	583	98.70	deposit	2024-03-04
3394	765	97.90	withdrawal	2024-04-12
3395	1645	112.70	deposit	2024-02-29
3396	375	24.20	deposit	2023-10-01
3397	52	192.00	withdrawal	2024-02-20
3398	1784	295.30	withdrawal	2024-02-04
3399	232	290.10	withdrawal	2023-09-28
3400	416	184.50	deposit	2024-02-09
3401	162	113.10	withdrawal	2023-09-05
3402	749	474.50	deposit	2024-01-15
3403	1533	95.60	withdrawal	2023-10-08
3404	1475	451.00	deposit	2024-05-27
3405	1498	57.60	withdrawal	2023-12-28
3406	660	195.10	deposit	2023-12-20
3407	463	313.30	deposit	2023-04-08
3408	1711	218.80	deposit	2023-10-25
3409	914	67.50	withdrawal	2023-02-04
3410	1741	82.40	deposit	2023-10-08
3411	1529	127.70	deposit	2024-02-23
3412	458	373.60	withdrawal	2024-01-29
3413	416	242.10	deposit	2023-03-27
3414	1091	164.60	withdrawal	2023-03-17
3415	27	194.00	deposit	2023-10-07
3416	209	398.50	withdrawal	2024-01-25
3417	50	272.40	withdrawal	2023-08-04
3418	1405	105.80	withdrawal	2023-11-08
3419	311	228.20	deposit	2023-04-29
3420	278	197.20	withdrawal	2023-07-29
3421	1646	115.00	deposit	2024-01-27
3422	1288	380.50	withdrawal	2023-05-13
3423	1477	226.20	deposit	2023-02-26
3424	548	91.30	deposit	2024-04-05
3425	1125	434.40	withdrawal	2023-06-26
3426	1505	103.20	deposit	2023-02-28
3427	754	122.30	deposit	2023-10-14
3428	752	214.30	deposit	2023-07-06
3429	1370	228.20	withdrawal	2024-01-15
3430	1595	465.10	withdrawal	2023-01-29
3431	487	207.20	deposit	2024-01-29
3432	507	500.00	withdrawal	2023-06-12
3433	1550	316.40	deposit	2023-08-15
3434	165	415.70	withdrawal	2023-05-29
3435	525	15.10	deposit	2023-11-29
3436	1193	67.80	deposit	2023-03-10
3437	690	392.30	withdrawal	2023-11-06
3438	202	466.60	deposit	2023-04-22
3439	1672	304.00	withdrawal	2024-01-16
3440	430	267.50	withdrawal	2023-06-21
3441	1532	286.40	deposit	2023-11-09
3442	1640	39.00	withdrawal	2023-09-10
3443	581	162.50	withdrawal	2023-02-21
3444	1359	168.60	deposit	2023-08-23
3445	1485	82.60	deposit	2023-10-10
3446	1579	320.00	withdrawal	2023-07-16
3447	1589	22.00	withdrawal	2023-12-12
3448	965	227.70	withdrawal	2023-03-09
3449	1560	105.40	deposit	2023-04-15
3450	1745	311.10	deposit	2023-04-15
3451	736	71.70	withdrawal	2023-09-13
3452	1680	165.60	withdrawal	2023-05-10
3453	98	475.60	deposit	2023-02-28
3454	1422	358.90	withdrawal	2024-03-21
3455	1675	95.90	withdrawal	2023-03-10
3456	141	251.10	deposit	2023-01-24
3457	1222	367.80	deposit	2023-02-18
3458	1422	288.20	deposit	2023-07-06
3459	1217	81.60	deposit	2024-01-17
3460	71	381.70	withdrawal	2024-05-01
3461	593	415.70	withdrawal	2023-10-31
3462	1350	376.80	deposit	2023-06-13
3463	1217	466.50	deposit	2023-11-03
3464	750	264.10	withdrawal	2023-03-02
3465	1070	463.30	withdrawal	2023-07-17
3466	24	138.40	withdrawal	2023-08-13
3467	1397	160.00	withdrawal	2023-11-04
3468	553	417.30	deposit	2023-09-15
3469	197	85.80	withdrawal	2023-11-11
3470	813	180.10	deposit	2023-04-14
3471	922	332.30	withdrawal	2023-06-30
3472	1761	139.60	withdrawal	2024-01-08
3473	1115	497.30	deposit	2024-01-04
3474	93	255.80	deposit	2023-08-17
3475	935	372.40	withdrawal	2023-06-07
3476	1551	164.90	deposit	2023-04-10
3477	1171	137.00	deposit	2023-10-05
3478	816	139.30	withdrawal	2024-02-17
3479	541	163.70	deposit	2023-07-18
3480	452	428.60	deposit	2024-05-19
3481	1605	117.70	withdrawal	2023-09-27
3482	1231	54.70	deposit	2023-03-27
3483	1735	315.90	deposit	2024-05-15
3484	1774	397.00	deposit	2023-03-26
3485	111	183.20	deposit	2023-12-14
3486	630	492.00	deposit	2024-04-30
3487	1692	75.70	deposit	2023-08-26
3488	1410	287.20	withdrawal	2024-04-28
3489	1482	21.30	deposit	2023-08-03
3490	517	11.20	deposit	2024-02-14
3491	423	194.50	deposit	2024-03-25
3492	1085	462.90	deposit	2023-01-01
3493	1105	425.30	deposit	2024-05-15
3494	472	175.70	deposit	2023-02-05
3495	781	8.60	withdrawal	2023-05-12
3496	1226	156.80	withdrawal	2023-03-09
3497	1022	315.30	deposit	2023-05-02
3498	1144	324.10	withdrawal	2024-03-29
3499	1631	433.50	deposit	2024-01-27
3500	1082	154.20	withdrawal	2023-06-10
3501	1667	457.70	deposit	2023-02-14
3502	1303	444.10	withdrawal	2023-02-12
3503	135	289.40	withdrawal	2023-10-30
3504	418	434.70	deposit	2024-04-13
3505	554	92.90	withdrawal	2023-05-14
3506	124	207.80	deposit	2023-11-20
3507	28	482.10	deposit	2023-05-27
3508	880	85.80	deposit	2024-05-03
3509	1098	295.90	deposit	2024-04-25
3510	1248	412.50	withdrawal	2023-11-26
3511	194	84.00	deposit	2024-02-10
3512	1657	281.60	deposit	2023-05-17
3513	746	425.60	deposit	2024-01-03
3514	337	118.30	deposit	2023-07-09
3515	439	10.80	deposit	2023-10-31
3516	325	21.00	withdrawal	2024-05-25
3517	1649	308.60	withdrawal	2023-11-30
3518	980	125.50	deposit	2023-06-28
3519	1275	456.00	deposit	2023-03-31
3520	1013	237.20	withdrawal	2023-02-14
3521	1439	11.00	deposit	2023-04-29
3522	1737	15.80	deposit	2024-04-29
3523	1660	30.30	withdrawal	2024-04-10
3524	441	465.00	withdrawal	2024-02-09
3525	356	285.30	withdrawal	2023-04-14
3526	719	360.90	withdrawal	2023-03-21
3527	1072	312.30	withdrawal	2024-02-20
3528	919	248.90	deposit	2024-03-27
3529	425	163.00	withdrawal	2024-01-13
3530	1100	446.00	withdrawal	2024-01-22
3531	961	286.40	deposit	2023-03-03
3532	1420	96.50	withdrawal	2023-08-17
3533	697	500.80	withdrawal	2023-03-10
3534	1226	32.20	deposit	2024-03-09
3535	2	498.40	deposit	2024-05-04
3536	1270	207.60	deposit	2023-04-06
3537	1682	324.90	withdrawal	2023-09-14
3538	971	325.00	deposit	2023-05-29
3539	1486	106.30	deposit	2023-09-07
3540	341	157.90	withdrawal	2024-02-21
3541	187	184.40	deposit	2023-08-28
3542	1752	301.50	withdrawal	2023-01-06
3543	280	246.10	withdrawal	2023-07-28
3544	299	203.60	withdrawal	2023-02-25
3545	1752	17.10	deposit	2023-07-24
3546	1424	285.90	withdrawal	2024-02-08
3547	818	186.20	withdrawal	2023-03-19
3548	220	111.50	withdrawal	2024-05-30
3549	1446	249.60	deposit	2024-01-20
3550	815	238.00	deposit	2023-04-04
3551	267	134.10	withdrawal	2023-11-06
3552	320	305.40	withdrawal	2024-05-13
3553	1214	50.70	deposit	2024-02-02
3554	1210	228.10	deposit	2024-03-10
3555	1798	34.70	withdrawal	2024-02-03
3556	1056	124.50	deposit	2024-02-27
3557	1486	487.60	deposit	2023-11-06
3558	725	170.90	withdrawal	2023-10-21
3559	871	81.20	withdrawal	2023-12-06
3560	715	401.70	deposit	2023-05-06
3561	142	126.50	withdrawal	2024-05-16
3562	734	38.90	deposit	2023-03-09
3563	1097	340.50	withdrawal	2023-11-07
3564	725	337.40	deposit	2024-05-16
3565	1243	235.50	withdrawal	2023-04-14
3566	1461	251.90	withdrawal	2023-07-02
3567	1604	94.10	withdrawal	2023-07-04
3568	326	278.00	withdrawal	2023-04-30
3569	1759	274.10	deposit	2023-04-04
3570	504	462.10	withdrawal	2023-02-06
3571	289	360.90	deposit	2023-06-14
3572	1141	298.40	deposit	2024-01-12
3573	1441	362.70	deposit	2023-12-10
3574	1292	50.60	deposit	2024-03-11
3575	845	10.20	deposit	2023-10-08
3576	1757	239.80	deposit	2023-07-16
3577	72	203.00	deposit	2023-03-26
3578	527	10.30	withdrawal	2023-11-11
3579	1387	407.10	withdrawal	2024-05-03
3580	973	229.50	withdrawal	2023-05-26
3581	621	123.50	deposit	2023-06-07
3582	239	291.20	withdrawal	2024-02-03
3583	642	317.60	withdrawal	2023-03-27
3584	486	425.10	withdrawal	2023-12-15
3585	1362	471.20	withdrawal	2024-02-27
3586	439	444.10	deposit	2024-01-14
3587	1372	334.90	deposit	2024-04-08
3588	1232	407.60	deposit	2024-04-15
3589	1459	93.70	withdrawal	2024-01-08
3590	1399	134.90	withdrawal	2023-09-17
3591	463	349.70	withdrawal	2023-04-07
3592	339	284.10	withdrawal	2024-04-25
3593	1435	478.50	deposit	2023-09-15
3594	183	133.30	deposit	2023-07-13
3595	966	126.40	withdrawal	2023-03-20
3596	414	492.90	deposit	2023-07-20
3597	1238	55.70	withdrawal	2024-04-07
3598	1548	319.60	withdrawal	2023-03-05
3599	404	158.00	deposit	2023-06-20
3600	1343	22.70	deposit	2023-02-09
3601	568	458.00	withdrawal	2023-10-14
3602	1360	57.70	deposit	2024-04-07
3603	623	103.60	deposit	2024-01-11
3604	129	432.30	deposit	2024-01-28
3605	497	431.80	withdrawal	2023-02-17
3606	87	319.30	withdrawal	2023-07-29
3607	1024	20.50	withdrawal	2023-04-01
3608	809	329.60	deposit	2023-10-13
3609	292	362.40	deposit	2023-04-26
3610	1594	163.00	deposit	2024-03-23
3611	1383	424.10	withdrawal	2023-09-30
3612	1483	320.50	withdrawal	2023-10-15
3613	1426	50.20	withdrawal	2024-04-20
3614	290	159.30	withdrawal	2023-12-14
3615	884	287.10	withdrawal	2024-03-17
3616	561	464.70	deposit	2023-09-02
3617	1414	406.60	deposit	2023-09-11
3618	415	385.70	deposit	2023-05-16
3619	695	337.50	withdrawal	2023-04-03
3620	1696	50.50	withdrawal	2024-05-31
3621	1294	60.40	withdrawal	2023-05-26
3622	22	59.60	withdrawal	2023-06-09
3623	12	465.90	deposit	2024-01-10
3624	1732	382.60	deposit	2024-02-17
3625	231	52.40	withdrawal	2024-05-19
3626	618	477.70	withdrawal	2024-01-03
3627	827	297.20	withdrawal	2024-05-04
3628	1659	25.60	deposit	2024-03-09
3629	1634	134.10	withdrawal	2023-03-21
3630	41	59.20	withdrawal	2024-04-17
3631	1058	463.00	deposit	2023-12-31
3632	1	256.40	deposit	2023-10-12
3633	1598	29.10	withdrawal	2023-08-28
3634	119	426.20	deposit	2023-08-17
3635	869	437.10	withdrawal	2023-10-12
3636	84	343.70	deposit	2023-12-15
3637	934	294.00	deposit	2024-03-18
3638	1511	301.30	withdrawal	2024-01-21
3639	795	111.40	withdrawal	2024-01-03
3640	1568	438.30	deposit	2023-08-11
3641	1724	78.30	withdrawal	2023-04-07
3642	537	206.70	withdrawal	2023-11-30
3643	1069	62.50	deposit	2023-10-28
3644	1463	243.90	withdrawal	2023-05-22
3645	1271	19.60	deposit	2023-09-24
3646	304	178.30	withdrawal	2023-04-22
3647	496	278.40	withdrawal	2023-07-20
3648	1184	286.00	deposit	2023-12-30
3649	903	101.40	withdrawal	2023-02-17
3650	452	108.90	withdrawal	2023-12-02
3651	277	284.20	withdrawal	2023-02-21
3652	1610	222.40	deposit	2023-12-03
3653	338	496.10	withdrawal	2023-02-10
3654	1449	53.70	withdrawal	2024-05-31
3655	710	170.10	withdrawal	2023-11-06
3656	235	134.00	deposit	2023-10-28
3657	455	100.70	deposit	2023-10-03
3658	1132	203.90	withdrawal	2023-12-18
3659	1392	136.60	withdrawal	2024-05-11
3660	1467	416.80	deposit	2023-03-25
3661	371	491.10	withdrawal	2023-11-12
3662	142	23.10	deposit	2023-09-16
3663	1015	12.70	deposit	2023-07-26
3664	139	419.60	withdrawal	2024-01-21
3665	1509	217.30	deposit	2023-01-30
3666	1444	334.90	deposit	2023-02-24
3667	132	205.00	deposit	2024-02-02
3668	806	312.90	withdrawal	2023-07-13
3669	699	64.40	withdrawal	2023-02-01
3670	1167	394.20	withdrawal	2023-02-15
3671	1218	391.10	deposit	2023-07-17
3672	1608	372.50	deposit	2023-09-22
3673	408	289.90	deposit	2023-05-02
3674	1573	145.30	deposit	2023-06-13
3675	932	29.40	deposit	2023-06-30
3676	119	138.00	deposit	2023-11-19
3677	11	442.60	withdrawal	2024-05-24
3678	259	137.00	withdrawal	2023-06-16
3679	1629	42.30	deposit	2024-05-24
3680	1173	239.60	withdrawal	2023-04-19
3681	1783	472.70	withdrawal	2023-03-18
3682	721	90.50	deposit	2024-03-27
3683	553	235.10	withdrawal	2023-10-30
3684	530	146.10	withdrawal	2023-05-08
3685	828	314.10	deposit	2023-10-28
3686	821	388.30	withdrawal	2023-11-13
3687	1148	453.50	deposit	2023-09-10
3688	1325	399.00	deposit	2023-01-11
3689	498	410.30	withdrawal	2023-08-29
3690	491	391.60	deposit	2023-09-01
3691	1215	66.70	withdrawal	2023-03-30
3692	410	465.40	deposit	2024-04-07
3693	1303	63.20	withdrawal	2023-01-08
3694	1478	409.10	withdrawal	2024-04-10
3695	50	470.30	withdrawal	2024-04-14
3696	1263	118.20	withdrawal	2023-12-25
3697	940	97.60	deposit	2023-07-12
3698	1362	120.70	withdrawal	2023-02-21
3699	526	54.90	deposit	2024-04-28
3700	521	418.00	deposit	2024-03-30
3701	1341	317.10	withdrawal	2023-06-27
3702	1323	306.50	deposit	2023-01-20
3703	1067	28.80	deposit	2024-01-26
3704	951	36.80	withdrawal	2024-02-03
3705	414	115.70	withdrawal	2023-06-14
3706	1679	372.70	deposit	2023-01-30
3707	372	334.50	withdrawal	2024-02-24
3708	1360	38.20	deposit	2024-04-16
3709	944	232.90	withdrawal	2023-07-19
3710	748	66.20	deposit	2024-01-04
3711	1184	97.20	deposit	2023-08-28
3712	887	451.90	deposit	2023-06-01
3713	579	19.30	withdrawal	2024-03-06
3714	482	119.00	withdrawal	2024-03-30
3715	720	461.10	deposit	2023-10-25
3716	669	359.40	withdrawal	2024-01-25
3717	322	493.30	deposit	2024-05-23
3718	1647	283.20	deposit	2023-12-19
3719	889	381.50	withdrawal	2023-02-01
3720	1384	424.40	deposit	2023-06-03
3721	440	461.40	deposit	2023-09-25
3722	218	367.30	withdrawal	2024-04-18
3723	118	470.00	deposit	2024-02-05
3724	830	465.80	deposit	2023-07-26
3725	1111	260.90	withdrawal	2024-01-06
3726	259	37.00	deposit	2023-11-17
3727	1732	405.50	withdrawal	2023-07-26
3728	608	143.60	withdrawal	2023-01-22
3729	649	155.20	deposit	2024-01-24
3730	966	229.40	withdrawal	2023-11-05
3731	1524	472.30	deposit	2023-08-30
3732	1400	221.30	deposit	2023-06-27
3733	1506	326.30	deposit	2023-03-25
3734	346	207.90	withdrawal	2023-05-24
3735	661	251.60	withdrawal	2023-02-14
3736	1379	100.70	withdrawal	2024-01-13
3737	1235	102.70	withdrawal	2023-03-14
3738	1007	128.00	withdrawal	2024-04-15
3739	1514	231.70	deposit	2024-05-27
3740	465	271.00	deposit	2023-07-11
3741	1117	373.90	deposit	2024-02-27
3742	497	441.90	withdrawal	2023-09-23
3743	223	393.00	withdrawal	2023-12-18
3744	894	446.60	deposit	2023-07-22
3745	1004	86.50	deposit	2023-12-26
3746	523	415.10	deposit	2023-02-20
3747	983	245.80	deposit	2023-08-15
3748	607	69.80	withdrawal	2024-01-20
3749	1740	396.70	deposit	2024-02-23
3750	1255	116.40	deposit	2024-05-18
3751	204	275.80	deposit	2024-05-15
3752	723	197.30	deposit	2024-05-14
3753	1729	402.90	withdrawal	2023-08-27
3754	173	256.30	deposit	2023-03-12
3755	1393	406.70	withdrawal	2023-08-06
3756	597	253.00	withdrawal	2023-04-24
3757	335	135.70	withdrawal	2023-07-09
3758	1436	36.50	withdrawal	2023-12-13
3759	803	19.10	deposit	2023-07-01
3760	985	478.50	deposit	2024-03-09
3761	1362	305.20	deposit	2023-01-09
3762	250	256.30	deposit	2023-02-09
3763	1519	435.20	deposit	2023-03-14
3764	201	347.80	withdrawal	2023-02-19
3765	1779	160.80	withdrawal	2024-01-14
3766	1769	86.30	withdrawal	2023-03-09
3767	1375	302.20	withdrawal	2023-12-21
3768	616	349.10	deposit	2023-10-27
3769	291	269.60	deposit	2023-08-29
3770	1344	342.70	deposit	2023-08-20
3771	398	435.50	deposit	2024-04-05
3772	155	410.80	withdrawal	2023-06-27
3773	281	368.50	withdrawal	2024-02-03
3774	1712	327.50	deposit	2023-06-08
3775	799	41.90	deposit	2023-01-22
3776	1313	238.80	deposit	2024-04-06
3777	1087	115.60	withdrawal	2023-10-24
3778	1489	453.70	deposit	2023-06-01
3779	987	499.60	withdrawal	2023-03-23
3780	1657	78.90	withdrawal	2024-04-03
3781	448	128.90	deposit	2023-09-19
3782	1494	350.00	deposit	2024-04-17
3783	837	331.30	deposit	2024-04-13
3784	727	117.40	withdrawal	2023-05-12
3785	1610	184.70	withdrawal	2024-04-06
3786	111	13.00	withdrawal	2023-07-02
3787	1650	47.40	deposit	2023-04-16
3788	232	499.30	deposit	2024-04-11
3789	927	393.60	withdrawal	2023-12-12
3790	1331	192.00	deposit	2024-01-14
3791	412	56.20	withdrawal	2024-03-24
3792	350	406.30	deposit	2023-08-21
3793	708	308.70	deposit	2023-02-12
3794	654	41.30	deposit	2024-04-20
3795	1096	70.00	deposit	2024-02-19
3796	113	58.60	withdrawal	2023-07-11
3797	1593	440.80	withdrawal	2024-03-28
3798	760	237.80	deposit	2023-04-16
3799	129	379.10	withdrawal	2023-08-05
3800	62	7.60	withdrawal	2024-03-25
3801	982	464.60	deposit	2023-01-15
3802	357	66.30	deposit	2023-03-07
3803	673	229.60	deposit	2023-08-29
3804	544	280.50	withdrawal	2024-04-02
3805	1722	363.30	withdrawal	2024-02-12
3806	266	173.60	deposit	2023-01-17
3807	1024	483.80	deposit	2023-12-22
3808	195	331.10	deposit	2023-11-09
3809	828	192.70	withdrawal	2024-04-03
3810	1409	50.70	deposit	2023-05-10
3811	416	237.60	deposit	2023-04-03
3812	783	445.10	deposit	2023-04-26
3813	1753	115.00	deposit	2023-04-24
3814	1106	463.90	deposit	2023-10-21
3815	77	202.30	deposit	2023-01-16
3816	1260	167.20	deposit	2023-08-31
3817	286	134.30	deposit	2023-04-28
3818	192	417.50	withdrawal	2023-03-03
3819	102	135.30	withdrawal	2023-12-02
3820	158	196.90	withdrawal	2024-05-18
3821	272	83.30	deposit	2023-03-24
3822	43	286.40	deposit	2024-01-22
3823	1564	459.20	withdrawal	2023-09-20
3824	1009	406.90	withdrawal	2023-11-28
3825	939	149.20	deposit	2023-06-01
3826	1230	141.10	withdrawal	2023-04-01
3827	1445	413.00	deposit	2023-02-27
3828	1488	10.20	deposit	2023-09-10
3829	1116	490.30	withdrawal	2023-01-03
3830	888	141.40	withdrawal	2023-03-03
3831	455	287.90	withdrawal	2024-04-18
3832	540	40.80	deposit	2023-01-30
3833	1056	325.30	deposit	2023-10-05
3834	1764	380.00	deposit	2023-03-23
3835	80	413.90	withdrawal	2023-10-07
3836	778	130.40	deposit	2023-09-19
3837	602	30.80	withdrawal	2024-04-11
3838	778	443.20	deposit	2023-08-18
3839	1740	200.20	deposit	2023-11-03
3840	1140	205.80	withdrawal	2023-12-04
3841	1514	233.80	deposit	2024-01-27
3842	1696	29.10	deposit	2023-08-01
3843	867	169.60	deposit	2024-01-17
3844	5	210.40	deposit	2023-08-07
3845	672	283.90	withdrawal	2023-02-02
3846	36	445.20	withdrawal	2023-01-04
3847	264	240.90	deposit	2023-01-19
3848	488	266.30	deposit	2023-07-12
3849	868	182.70	deposit	2024-04-04
3850	513	270.40	withdrawal	2023-03-14
3851	410	69.90	withdrawal	2024-04-19
3852	815	165.30	withdrawal	2024-02-15
3853	1497	143.00	withdrawal	2023-10-14
3854	309	173.70	deposit	2023-09-11
3855	1544	462.90	deposit	2023-08-06
3856	971	456.00	deposit	2024-03-14
3857	1259	160.70	deposit	2024-05-27
3858	1775	315.40	withdrawal	2023-09-17
3859	605	398.30	deposit	2023-12-06
3860	127	445.00	withdrawal	2023-08-03
3861	407	456.50	deposit	2023-03-13
3862	1520	333.90	withdrawal	2023-06-24
3863	1156	212.10	withdrawal	2023-07-13
3864	261	303.90	deposit	2023-05-24
3865	1698	441.80	deposit	2023-01-13
3866	594	436.40	withdrawal	2023-03-14
3867	153	485.30	withdrawal	2023-11-16
3868	168	473.70	withdrawal	2023-06-20
3869	275	296.40	deposit	2024-02-13
3870	676	188.40	deposit	2024-05-04
3871	336	445.20	deposit	2023-10-28
3872	245	327.90	withdrawal	2024-02-11
3873	1800	365.60	deposit	2023-10-13
3874	638	28.30	deposit	2023-03-18
3875	161	115.50	withdrawal	2024-05-03
3876	154	116.00	withdrawal	2024-04-01
3877	610	55.00	deposit	2024-04-12
3878	795	123.10	withdrawal	2023-06-18
3879	1522	30.80	deposit	2023-01-01
3880	517	387.40	withdrawal	2024-01-26
3881	1780	449.00	withdrawal	2023-11-08
3882	1030	333.30	withdrawal	2023-11-04
3883	1284	164.80	withdrawal	2023-02-14
3884	841	146.50	deposit	2024-03-23
3885	541	145.80	withdrawal	2024-03-25
3886	441	275.90	withdrawal	2023-01-09
3887	723	88.10	deposit	2023-06-20
3888	864	425.20	withdrawal	2023-10-30
3889	973	87.80	withdrawal	2023-01-10
3890	1395	109.90	withdrawal	2023-10-07
3891	1485	170.20	deposit	2024-04-23
3892	1615	477.60	withdrawal	2023-09-30
3893	588	7.10	withdrawal	2023-04-09
3894	749	344.20	withdrawal	2024-04-24
3895	332	185.10	deposit	2024-05-21
3896	510	363.20	withdrawal	2023-12-04
3897	1070	201.80	deposit	2023-12-03
3898	1250	380.60	withdrawal	2023-09-21
3899	1351	142.70	withdrawal	2023-01-14
3900	76	203.20	deposit	2023-03-11
3901	360	9.70	deposit	2024-05-10
3902	1787	78.60	withdrawal	2023-04-11
3903	1476	411.40	deposit	2023-09-30
3904	424	59.00	withdrawal	2023-08-03
3905	260	32.60	withdrawal	2023-03-03
3906	490	145.00	deposit	2023-05-03
3907	1784	302.40	withdrawal	2023-05-11
3908	1378	293.90	deposit	2023-01-19
3909	557	484.40	withdrawal	2024-02-12
3910	1796	283.30	deposit	2023-08-26
3911	202	75.80	withdrawal	2023-05-29
3912	1614	181.70	deposit	2023-06-03
3913	190	339.40	withdrawal	2023-10-29
3914	228	101.50	withdrawal	2023-10-02
3915	1774	285.90	deposit	2023-08-23
3916	89	270.50	withdrawal	2023-03-06
3917	749	394.90	withdrawal	2023-10-19
3918	1745	155.70	deposit	2024-04-19
3919	1527	156.70	deposit	2023-12-21
3920	1521	88.10	withdrawal	2024-01-07
3921	905	415.90	withdrawal	2023-07-25
3922	436	257.20	withdrawal	2023-05-05
3923	1060	442.40	deposit	2023-07-22
3924	431	468.10	withdrawal	2024-01-19
3925	103	499.10	deposit	2023-06-22
3926	263	348.00	deposit	2024-05-23
3927	273	15.90	withdrawal	2023-04-06
3928	290	56.40	deposit	2023-05-19
3929	566	371.60	withdrawal	2023-03-03
3930	1249	347.90	deposit	2023-05-21
3931	1642	409.20	withdrawal	2023-06-19
3932	1391	28.40	deposit	2023-12-03
3933	1724	429.50	withdrawal	2023-11-09
3934	1710	25.00	withdrawal	2023-04-29
3935	1360	7.60	deposit	2023-08-22
3936	390	33.30	withdrawal	2023-10-09
3937	301	424.80	withdrawal	2023-03-16
3938	919	264.70	deposit	2023-09-30
3939	332	448.40	withdrawal	2023-10-13
3940	789	475.50	deposit	2023-11-13
3941	861	131.20	deposit	2023-10-04
3942	1125	26.40	deposit	2023-07-20
3943	849	313.00	deposit	2023-11-19
3944	610	272.70	withdrawal	2024-02-29
3945	853	324.20	withdrawal	2023-04-24
3946	641	275.50	withdrawal	2023-01-13
3947	1345	57.70	deposit	2023-10-26
3948	599	420.60	withdrawal	2023-04-13
3949	448	297.50	withdrawal	2023-04-17
3950	1726	382.70	withdrawal	2024-02-15
3951	857	332.20	withdrawal	2024-03-09
3952	124	76.30	deposit	2023-10-21
3953	1135	145.10	withdrawal	2023-06-28
3954	916	8.20	withdrawal	2024-01-24
3955	75	134.00	withdrawal	2023-08-09
3956	1318	199.30	withdrawal	2023-01-31
3957	499	352.00	deposit	2023-04-04
3958	923	236.60	deposit	2023-08-28
3959	1399	473.40	withdrawal	2024-02-14
3960	252	316.10	withdrawal	2023-04-06
3961	869	351.10	deposit	2024-02-23
3962	833	331.20	withdrawal	2023-05-06
3963	331	430.60	deposit	2023-04-14
3964	700	135.10	deposit	2023-01-18
3965	1512	166.00	withdrawal	2023-03-07
3966	1704	375.00	withdrawal	2024-03-03
3967	253	348.50	withdrawal	2024-04-03
3968	48	189.50	deposit	2024-03-18
3969	1615	491.30	withdrawal	2023-01-19
3970	965	326.70	deposit	2024-02-23
3971	598	498.20	withdrawal	2024-05-10
3972	406	164.10	deposit	2023-12-31
3973	11	126.20	deposit	2024-04-23
3974	362	431.90	withdrawal	2023-04-05
3975	778	236.10	deposit	2023-01-08
3976	1005	456.50	withdrawal	2023-08-26
3977	581	460.40	deposit	2023-01-25
3978	443	305.10	withdrawal	2023-11-22
3979	1266	341.90	deposit	2023-09-06
3980	1413	243.60	deposit	2024-03-11
3981	920	192.00	withdrawal	2023-10-29
3982	495	152.00	deposit	2024-05-31
3983	1015	134.00	deposit	2023-07-21
3984	329	364.40	withdrawal	2024-02-12
3985	476	288.00	withdrawal	2023-01-23
3986	863	337.40	withdrawal	2023-11-25
3987	634	454.00	withdrawal	2024-04-17
3988	1533	313.20	withdrawal	2023-11-06
3989	1224	483.40	withdrawal	2023-09-18
3990	346	421.50	withdrawal	2023-11-12
3991	1309	216.50	deposit	2023-03-25
3992	233	182.30	withdrawal	2023-08-04
3993	1321	219.30	deposit	2024-05-03
3994	232	212.70	withdrawal	2024-04-25
3995	965	208.20	deposit	2023-02-25
3996	403	398.10	deposit	2023-02-03
3997	710	283.80	deposit	2024-04-04
3998	1505	265.30	deposit	2023-11-16
3999	1765	267.20	withdrawal	2023-03-08
4000	1339	158.10	withdrawal	2024-04-15
4001	1054	12.40	withdrawal	2024-01-17
4002	1765	100.50	deposit	2023-06-25
4003	158	451.40	withdrawal	2023-03-25
4004	466	115.60	withdrawal	2024-04-02
4005	1763	284.80	withdrawal	2023-04-10
4006	112	110.70	deposit	2023-12-07
4007	1262	85.70	deposit	2024-02-09
4008	1249	432.70	withdrawal	2024-04-26
4009	1326	429.50	withdrawal	2023-05-01
4010	423	409.40	withdrawal	2024-01-26
4011	1266	31.20	withdrawal	2023-10-26
4012	92	63.90	deposit	2023-06-24
4013	402	140.90	withdrawal	2024-01-14
4014	267	166.90	deposit	2024-05-23
4015	201	279.90	deposit	2024-04-21
4016	24	116.20	deposit	2023-12-06
4017	1159	24.20	withdrawal	2024-02-16
4018	1565	191.30	withdrawal	2023-12-05
4019	1766	29.60	deposit	2023-11-28
4020	76	216.00	withdrawal	2024-03-28
4021	614	491.30	deposit	2023-07-16
4022	967	372.10	withdrawal	2024-03-23
4023	512	270.20	withdrawal	2023-08-02
4024	1161	96.60	withdrawal	2023-12-04
4025	304	241.60	deposit	2023-11-28
4026	634	231.10	deposit	2024-03-09
4027	629	492.20	withdrawal	2024-01-31
4028	818	68.10	withdrawal	2024-04-16
4029	832	28.20	withdrawal	2023-04-24
4030	1628	97.80	withdrawal	2023-02-21
4031	1392	419.70	withdrawal	2023-02-17
4032	850	116.40	withdrawal	2023-08-19
4033	1697	426.10	deposit	2024-05-26
4034	18	19.70	withdrawal	2023-12-14
4035	268	312.60	withdrawal	2023-01-05
4036	919	146.40	deposit	2023-08-29
4037	980	439.00	withdrawal	2023-09-19
4038	1741	468.80	withdrawal	2023-10-26
4039	901	300.00	deposit	2024-04-30
4040	1363	409.50	withdrawal	2024-04-03
4041	1730	195.00	deposit	2023-08-01
4042	547	354.40	withdrawal	2024-05-12
4043	32	393.80	withdrawal	2024-04-07
4044	806	469.40	withdrawal	2023-07-15
4045	1223	250.80	deposit	2024-03-22
4046	1344	489.50	withdrawal	2023-08-18
4047	772	135.70	deposit	2023-10-15
4048	142	465.80	deposit	2023-04-05
4049	1456	131.70	deposit	2024-01-12
4050	678	256.90	deposit	2023-03-14
4051	1305	114.10	deposit	2024-02-17
4052	966	323.10	withdrawal	2024-02-12
4053	1533	427.60	withdrawal	2023-10-02
4054	241	241.80	deposit	2023-06-30
4055	1763	64.80	deposit	2023-09-30
4056	860	179.20	withdrawal	2024-03-26
4057	1478	318.80	withdrawal	2024-03-08
4058	1360	163.00	withdrawal	2023-03-15
4059	401	46.00	deposit	2023-07-11
4060	870	144.10	deposit	2024-02-08
4061	539	297.20	deposit	2024-04-17
4062	925	270.20	deposit	2023-10-05
4063	799	438.60	withdrawal	2023-04-11
4064	1372	454.20	deposit	2023-06-21
4065	1677	340.10	withdrawal	2023-12-24
4066	404	94.80	withdrawal	2023-07-05
4067	936	380.30	withdrawal	2023-02-25
4068	463	131.00	withdrawal	2024-03-30
4069	1332	79.30	withdrawal	2023-01-01
4070	265	353.50	deposit	2023-08-23
4071	1479	210.10	deposit	2024-02-13
4072	680	364.50	withdrawal	2023-06-05
4073	1727	494.60	deposit	2023-09-02
4074	207	51.50	deposit	2023-03-02
4075	1740	121.90	withdrawal	2023-12-26
4076	146	375.60	deposit	2024-02-24
4077	513	299.90	deposit	2023-03-12
4078	103	461.60	deposit	2024-01-02
4079	403	8.60	deposit	2023-05-27
4080	636	178.90	deposit	2023-08-13
4081	1126	250.00	withdrawal	2023-01-22
4082	1714	423.00	deposit	2023-10-29
4083	347	166.30	deposit	2023-01-09
4084	974	455.70	deposit	2023-07-04
4085	1374	109.80	deposit	2023-04-01
4086	573	407.20	withdrawal	2023-10-29
4087	915	52.20	deposit	2023-11-23
4088	1568	266.50	deposit	2023-05-31
4089	1324	238.80	deposit	2024-01-07
4090	1223	281.90	withdrawal	2023-06-16
4091	87	212.40	withdrawal	2024-01-03
4092	661	57.90	deposit	2023-10-05
4093	1040	96.10	deposit	2023-08-08
4094	1517	490.80	withdrawal	2023-08-28
4095	1210	283.30	deposit	2023-10-06
4096	500	45.10	withdrawal	2024-01-08
4097	632	450.80	deposit	2023-04-24
4098	327	497.90	deposit	2023-12-26
4099	1475	475.30	deposit	2024-03-14
4100	430	367.50	withdrawal	2023-02-10
4101	1271	333.30	withdrawal	2023-07-12
4102	1260	241.00	withdrawal	2023-07-05
4103	869	11.30	deposit	2024-03-01
4104	91	142.30	withdrawal	2023-10-14
4105	589	358.10	deposit	2023-07-31
4106	633	451.70	withdrawal	2024-01-20
4107	1171	458.40	withdrawal	2024-03-24
4108	1245	122.20	deposit	2024-04-16
4109	470	270.80	withdrawal	2023-02-26
4110	1277	399.20	withdrawal	2023-07-07
4111	523	279.10	withdrawal	2023-02-04
4112	1281	113.90	deposit	2023-06-01
4113	165	413.50	deposit	2023-12-07
4114	567	50.40	withdrawal	2023-11-20
4115	838	43.20	withdrawal	2024-01-16
4116	1777	449.10	deposit	2023-06-06
4117	326	295.30	withdrawal	2023-10-03
4118	903	20.60	deposit	2023-11-22
4119	918	82.20	deposit	2023-12-08
4120	1498	196.30	withdrawal	2023-03-25
4121	1644	172.30	withdrawal	2023-02-14
4122	765	315.70	deposit	2023-05-01
4123	1578	386.40	withdrawal	2023-02-24
4124	1061	83.70	deposit	2024-04-20
4125	526	109.20	deposit	2023-04-20
4126	482	173.60	deposit	2023-07-21
4127	1004	113.50	deposit	2024-03-14
4128	1766	37.50	withdrawal	2023-06-21
4129	1297	393.50	deposit	2024-05-25
4130	734	252.30	deposit	2023-08-21
4131	661	418.10	deposit	2024-01-04
4132	334	97.70	deposit	2024-01-09
4133	1370	454.90	deposit	2023-05-26
4134	1463	428.10	withdrawal	2023-09-07
4135	983	320.40	withdrawal	2023-01-24
4136	1678	459.00	deposit	2023-07-10
4137	1296	65.50	deposit	2024-04-21
4138	383	491.70	withdrawal	2024-02-23
4139	1436	232.50	deposit	2024-04-04
4140	1496	187.30	deposit	2024-04-17
4141	273	276.40	deposit	2023-05-12
4142	1533	26.50	withdrawal	2023-11-22
4143	590	464.40	deposit	2024-03-20
4144	1418	478.10	deposit	2023-01-13
4145	1579	35.90	withdrawal	2024-01-01
4146	1166	176.50	deposit	2023-02-12
4147	473	196.20	withdrawal	2023-05-26
4148	905	342.50	deposit	2024-02-15
4149	154	151.00	withdrawal	2023-12-30
4150	415	341.70	withdrawal	2023-10-10
4151	450	409.90	deposit	2023-10-31
4152	1793	125.90	deposit	2024-03-08
4153	1593	145.00	withdrawal	2023-08-24
4154	630	255.70	withdrawal	2024-01-31
4155	1452	376.70	withdrawal	2023-03-31
4156	644	145.90	withdrawal	2023-11-16
4157	1167	35.20	deposit	2023-11-13
4158	821	192.70	deposit	2024-03-24
4159	1362	108.50	withdrawal	2023-06-04
4160	1348	483.60	withdrawal	2023-03-24
4161	790	356.30	withdrawal	2023-11-24
4162	1670	12.10	withdrawal	2024-04-29
4163	1111	57.90	deposit	2024-05-18
4164	1299	12.80	deposit	2023-01-09
4165	1323	209.20	deposit	2024-05-09
4166	602	402.50	withdrawal	2023-09-30
4167	433	402.00	withdrawal	2023-10-23
4168	961	352.60	deposit	2023-02-16
4169	1376	364.10	withdrawal	2023-11-02
4170	586	410.00	deposit	2024-02-11
4171	987	475.20	deposit	2024-05-09
4172	884	65.00	deposit	2024-03-17
4173	484	33.10	withdrawal	2023-08-29
4174	73	294.20	deposit	2023-12-17
4175	801	220.80	deposit	2023-06-24
4176	1622	226.00	deposit	2023-06-10
4177	1377	285.00	deposit	2024-04-02
4178	841	60.20	deposit	2023-04-20
4179	142	258.10	withdrawal	2023-06-25
4180	696	12.60	withdrawal	2023-12-17
4181	664	458.20	deposit	2023-11-21
4182	965	293.70	withdrawal	2023-04-16
4183	700	212.20	withdrawal	2023-07-30
4184	1101	209.80	deposit	2023-11-30
4185	1234	133.20	withdrawal	2024-04-10
4186	1412	325.10	withdrawal	2023-04-26
4187	1282	493.60	withdrawal	2023-06-30
4188	733	353.50	deposit	2024-01-12
4189	1387	411.10	withdrawal	2023-02-21
4190	1480	204.40	deposit	2023-08-27
4191	251	246.50	withdrawal	2023-12-23
4192	1764	375.20	withdrawal	2024-03-03
4193	1316	74.40	withdrawal	2024-04-09
4194	1287	381.30	deposit	2023-07-23
4195	1289	301.40	deposit	2023-02-16
4196	942	425.40	deposit	2024-05-19
4197	908	464.90	deposit	2023-11-24
4198	1369	304.80	deposit	2023-01-13
4199	343	147.50	deposit	2023-06-29
4200	66	113.50	withdrawal	2023-10-26
4201	1384	370.70	deposit	2023-02-17
4202	261	405.80	deposit	2023-12-06
4203	1617	105.10	deposit	2024-03-03
4204	1621	59.80	withdrawal	2023-12-10
4205	1572	55.30	withdrawal	2024-04-10
4206	1628	132.30	deposit	2024-01-17
4207	479	205.10	withdrawal	2024-03-07
4208	545	56.30	deposit	2024-05-13
4209	598	244.80	deposit	2024-01-04
4210	866	257.40	withdrawal	2023-04-20
4211	1007	277.80	withdrawal	2024-03-21
4212	1601	212.90	withdrawal	2024-03-24
4213	1046	140.50	deposit	2023-04-01
4214	1643	327.30	deposit	2023-11-15
4215	713	489.80	withdrawal	2024-04-14
4216	1504	299.00	deposit	2024-03-19
4217	5	315.00	deposit	2024-02-22
4218	151	285.20	withdrawal	2023-08-07
4219	35	322.30	deposit	2024-01-15
4220	982	464.50	withdrawal	2023-08-17
4221	671	100.30	withdrawal	2024-01-23
4222	1752	185.60	withdrawal	2024-05-23
4223	290	103.50	deposit	2023-01-29
4224	1010	327.70	withdrawal	2024-05-19
4225	1577	106.10	deposit	2023-03-11
4226	1262	384.40	deposit	2023-04-27
4227	761	452.30	deposit	2023-11-14
4228	1439	217.00	deposit	2024-05-19
4229	1798	296.50	withdrawal	2023-10-09
4230	364	323.80	withdrawal	2024-04-20
4231	155	169.60	withdrawal	2023-12-12
4232	721	334.60	withdrawal	2023-12-10
4233	1759	6.40	deposit	2024-01-09
4234	1285	466.70	deposit	2023-06-08
4235	1096	242.90	deposit	2024-01-04
4236	391	451.50	withdrawal	2024-04-30
4237	1314	16.00	withdrawal	2024-05-31
4238	720	302.50	deposit	2023-05-29
4239	720	68.40	withdrawal	2023-03-19
4240	1412	71.00	withdrawal	2023-02-21
4241	22	461.80	deposit	2023-05-15
4242	673	402.60	withdrawal	2024-05-08
4243	915	173.80	deposit	2023-04-03
4244	1359	229.30	withdrawal	2024-01-29
4245	1070	374.90	withdrawal	2023-10-31
4246	839	323.00	withdrawal	2023-08-05
4247	732	362.70	deposit	2023-01-15
4248	934	137.20	withdrawal	2023-05-17
4249	1428	356.20	deposit	2023-09-07
4250	1559	386.10	withdrawal	2023-11-18
4251	28	298.40	withdrawal	2023-07-21
4252	1122	418.80	withdrawal	2023-01-28
4253	585	261.00	deposit	2024-05-13
4254	1041	467.90	deposit	2023-03-03
4255	765	214.90	deposit	2023-01-27
4256	1340	276.30	deposit	2023-10-02
4257	418	203.40	withdrawal	2023-05-07
4258	164	406.90	withdrawal	2023-12-31
4259	753	462.10	withdrawal	2023-02-09
4260	729	77.30	deposit	2024-03-21
4261	120	12.00	deposit	2023-12-20
4262	1307	31.70	withdrawal	2023-12-03
4263	1653	111.10	deposit	2024-04-25
4264	1633	202.30	deposit	2023-04-07
4265	300	153.00	deposit	2023-10-04
4266	452	136.80	withdrawal	2023-02-18
4267	189	92.50	withdrawal	2024-03-19
4268	1117	209.60	withdrawal	2023-11-25
4269	1039	284.80	deposit	2023-12-20
4270	4	431.60	withdrawal	2023-12-23
4271	785	493.40	withdrawal	2023-12-15
4272	1762	452.10	deposit	2023-06-23
4273	432	361.00	deposit	2023-10-07
4274	1746	225.30	withdrawal	2023-03-17
4275	447	337.70	withdrawal	2024-01-12
4276	282	477.10	deposit	2023-07-19
4277	1772	185.40	withdrawal	2023-06-19
4278	305	494.60	withdrawal	2023-05-09
4279	615	195.40	withdrawal	2023-08-09
4280	624	120.20	withdrawal	2023-01-02
4281	688	318.00	withdrawal	2023-02-10
4282	117	62.80	deposit	2023-01-07
4283	253	305.90	withdrawal	2024-03-09
4284	1468	278.30	withdrawal	2024-04-25
4285	147	6.80	deposit	2023-09-28
4286	830	483.40	deposit	2023-01-12
4287	1349	287.30	deposit	2023-05-05
4288	1536	139.30	withdrawal	2023-06-19
4289	47	213.10	deposit	2024-01-11
4290	997	365.60	withdrawal	2023-04-13
4291	209	410.10	withdrawal	2023-10-29
4292	940	321.10	withdrawal	2023-04-24
4293	1508	439.30	deposit	2024-03-18
4294	960	292.00	deposit	2023-11-12
4295	481	443.40	deposit	2023-05-28
4296	320	105.00	deposit	2024-01-20
4297	366	169.90	deposit	2023-11-27
4298	35	287.20	withdrawal	2024-01-11
4299	1503	265.90	deposit	2024-02-24
4300	1656	453.60	withdrawal	2023-08-13
4301	1286	245.40	deposit	2023-03-04
4302	1426	140.60	withdrawal	2024-03-03
4303	26	72.00	deposit	2023-08-10
4304	1728	161.50	deposit	2023-03-16
4305	1474	130.90	deposit	2023-01-27
4306	1554	296.70	withdrawal	2024-02-14
4307	1483	8.40	withdrawal	2023-01-11
4308	725	474.20	withdrawal	2024-05-09
4309	206	66.80	deposit	2024-01-10
4310	828	349.20	withdrawal	2023-10-12
4311	1766	57.90	withdrawal	2024-02-12
4312	54	12.60	deposit	2023-08-21
4313	769	143.50	deposit	2023-03-06
4314	351	7.30	deposit	2024-05-14
4315	1586	166.30	withdrawal	2023-12-06
4316	128	475.80	deposit	2024-02-09
4317	1328	256.70	withdrawal	2023-01-31
4318	1019	247.70	withdrawal	2023-08-31
4319	1776	487.70	deposit	2023-06-03
4320	622	401.60	withdrawal	2024-05-21
4321	103	241.40	withdrawal	2024-03-08
4322	1297	39.30	deposit	2023-12-29
4323	447	294.60	withdrawal	2023-09-23
4324	1727	232.50	withdrawal	2023-06-24
4325	1199	471.00	withdrawal	2023-02-24
4326	475	13.80	deposit	2023-02-12
4327	1212	292.90	withdrawal	2024-02-24
4328	642	270.90	deposit	2023-12-20
4329	1019	15.80	deposit	2024-02-17
4330	776	134.30	deposit	2024-03-19
4331	1145	492.90	withdrawal	2023-06-28
4332	819	98.80	withdrawal	2023-08-15
4333	789	163.50	withdrawal	2023-12-14
4334	649	444.90	withdrawal	2023-10-27
4335	1631	205.00	deposit	2023-09-09
4336	170	418.20	deposit	2023-05-08
4337	761	497.40	deposit	2023-04-07
4338	1007	391.90	withdrawal	2023-07-05
4339	301	385.30	deposit	2024-05-26
4340	34	242.60	deposit	2023-03-23
4341	1484	253.30	withdrawal	2023-02-28
4342	1796	465.70	withdrawal	2024-01-03
4343	425	322.10	deposit	2023-01-23
4344	1570	426.70	deposit	2023-01-22
4345	1295	453.10	deposit	2023-05-13
4346	488	30.60	deposit	2024-05-11
4347	255	66.20	deposit	2023-03-16
4348	833	466.60	withdrawal	2023-04-24
4349	1429	207.60	withdrawal	2023-10-30
4350	1683	127.50	deposit	2023-11-11
4351	641	30.50	deposit	2023-01-21
4352	1039	284.30	deposit	2023-03-11
4353	1380	198.90	deposit	2024-04-16
4354	37	65.30	withdrawal	2023-05-12
4355	1145	42.30	deposit	2023-06-09
4356	1676	134.20	withdrawal	2024-03-18
4357	801	413.50	deposit	2023-08-12
4358	1395	483.60	deposit	2023-12-05
4359	1794	209.40	deposit	2024-05-07
4360	614	480.00	deposit	2024-04-30
4361	1276	269.80	deposit	2024-04-18
4362	579	20.00	withdrawal	2024-02-16
4363	1713	289.00	withdrawal	2024-01-11
4364	1599	24.50	deposit	2024-01-25
4365	1734	408.90	withdrawal	2023-01-01
4366	744	436.00	withdrawal	2023-05-30
4367	1656	49.80	deposit	2023-12-30
4368	519	250.50	deposit	2023-08-14
4369	945	475.00	deposit	2024-03-23
4370	1522	297.30	deposit	2023-08-11
4371	1300	115.80	withdrawal	2024-05-06
4372	276	367.00	deposit	2023-12-18
4373	1049	108.40	withdrawal	2023-02-07
4374	718	341.30	withdrawal	2023-07-27
4375	1267	10.60	deposit	2023-02-08
4376	1138	265.30	deposit	2023-01-29
4377	753	419.70	withdrawal	2023-01-09
4378	477	343.60	withdrawal	2023-08-17
4379	1060	123.40	deposit	2024-02-18
4380	1134	447.00	withdrawal	2023-02-23
4381	586	424.60	withdrawal	2023-01-25
4382	104	186.50	deposit	2023-08-20
4383	1739	194.40	deposit	2024-01-05
4384	721	201.70	withdrawal	2023-06-18
4385	1712	324.50	withdrawal	2024-05-12
4386	1346	465.80	withdrawal	2023-12-12
4387	539	16.70	withdrawal	2024-01-13
4388	1387	191.90	withdrawal	2023-11-08
4389	92	284.30	withdrawal	2024-02-11
4390	628	334.10	deposit	2024-01-24
4391	1321	17.10	withdrawal	2024-02-21
4392	1123	257.00	deposit	2024-05-12
4393	133	73.90	withdrawal	2024-04-19
4394	1202	147.60	deposit	2023-01-16
4395	978	41.80	deposit	2023-11-25
4396	907	184.00	deposit	2023-12-07
4397	1136	57.60	deposit	2024-03-23
4398	84	216.70	withdrawal	2024-01-24
4399	508	245.40	withdrawal	2024-05-19
4400	1351	450.10	withdrawal	2023-06-03
4401	701	339.30	withdrawal	2023-08-03
4402	878	70.90	withdrawal	2024-03-31
4403	318	123.80	deposit	2023-04-23
4404	154	491.00	deposit	2024-03-15
4405	1749	205.70	withdrawal	2024-03-07
4406	1782	416.80	deposit	2024-04-01
4407	960	12.90	withdrawal	2023-01-03
4408	249	458.70	deposit	2023-10-06
4409	1297	148.10	deposit	2024-01-24
4410	353	472.10	deposit	2023-09-01
4411	860	378.80	deposit	2023-05-28
4412	1353	156.10	deposit	2024-05-08
4413	1062	158.50	withdrawal	2023-09-13
4414	1131	27.40	deposit	2023-03-19
4415	1700	389.00	withdrawal	2023-02-26
4416	602	297.30	deposit	2023-06-14
4417	552	347.30	withdrawal	2023-09-30
4418	162	405.20	withdrawal	2023-01-13
4419	320	34.40	deposit	2023-10-18
4420	27	398.00	deposit	2023-07-12
4421	85	370.20	deposit	2023-03-26
4422	91	127.50	deposit	2023-04-26
4423	1715	262.90	withdrawal	2023-05-06
4424	711	67.30	withdrawal	2024-01-03
4425	1202	171.80	deposit	2024-02-12
4426	332	441.50	deposit	2023-03-17
4427	586	418.90	withdrawal	2024-04-24
4428	1157	184.30	withdrawal	2024-04-11
4429	812	442.00	deposit	2023-04-29
4430	1382	178.70	deposit	2023-03-06
4431	783	312.20	withdrawal	2024-03-01
4432	1362	363.10	withdrawal	2024-01-30
4433	889	229.80	withdrawal	2023-01-31
4434	420	231.50	deposit	2024-03-01
4435	466	417.20	deposit	2023-10-09
4436	1186	37.00	withdrawal	2024-01-30
4437	94	460.20	withdrawal	2023-06-18
4438	231	256.10	deposit	2023-08-03
4439	1619	442.20	withdrawal	2023-03-24
4440	1152	193.10	withdrawal	2024-02-04
4441	1006	386.30	deposit	2023-01-06
4442	406	102.60	withdrawal	2024-01-04
4443	1733	375.90	deposit	2023-06-23
4444	880	322.90	withdrawal	2023-11-20
4445	968	98.90	deposit	2023-01-13
4446	377	341.10	withdrawal	2023-08-18
4447	1138	139.50	withdrawal	2023-10-08
4448	82	383.80	withdrawal	2024-01-09
4449	543	304.20	withdrawal	2023-11-25
4450	1757	160.10	withdrawal	2023-08-10
4451	73	269.90	deposit	2023-04-14
4452	305	176.00	deposit	2023-04-30
4453	966	220.40	withdrawal	2023-12-10
4454	1289	241.20	withdrawal	2023-04-19
4455	516	130.30	withdrawal	2024-02-13
4456	313	232.50	deposit	2023-04-19
4457	815	205.20	deposit	2023-05-07
4458	307	146.00	deposit	2024-04-19
4459	1074	32.90	deposit	2023-07-27
4460	243	19.40	deposit	2024-05-26
4461	834	257.30	deposit	2024-04-01
4462	1516	441.40	withdrawal	2023-06-08
4463	1413	15.00	withdrawal	2023-05-31
4464	1636	58.70	deposit	2024-01-12
4465	163	373.90	deposit	2023-01-09
4466	410	111.90	withdrawal	2023-11-16
4467	72	161.70	withdrawal	2023-11-12
4468	352	445.90	deposit	2024-03-18
4469	104	285.20	withdrawal	2024-05-08
4470	940	314.00	deposit	2023-07-23
4471	1453	208.80	deposit	2023-03-16
4472	1621	124.20	deposit	2024-02-14
4473	1634	216.80	withdrawal	2023-09-06
4474	700	278.80	deposit	2023-09-16
4475	1319	73.90	withdrawal	2023-08-16
4476	1065	13.30	withdrawal	2023-11-05
4477	430	72.60	deposit	2024-05-18
4478	1636	340.50	withdrawal	2023-10-11
4479	1339	61.40	deposit	2023-03-22
4480	1312	124.30	withdrawal	2023-06-02
4481	457	23.10	withdrawal	2023-08-12
4482	968	35.40	withdrawal	2023-09-01
4483	940	486.20	withdrawal	2024-02-16
4484	1186	168.90	withdrawal	2023-12-29
4485	371	139.60	withdrawal	2024-02-03
4486	1013	500.50	deposit	2023-06-01
4487	837	318.20	withdrawal	2023-08-18
4488	1579	459.30	deposit	2023-02-16
4489	333	63.60	deposit	2023-09-16
4490	1131	358.60	withdrawal	2023-05-08
4491	421	243.90	deposit	2024-01-04
4492	646	98.20	withdrawal	2024-04-07
4493	377	99.50	deposit	2024-05-03
4494	1440	388.50	deposit	2023-07-15
4495	639	250.30	withdrawal	2024-04-17
4496	703	183.60	withdrawal	2023-02-09
4497	219	46.70	withdrawal	2023-09-16
4498	1000	270.10	deposit	2023-05-18
4499	324	448.40	deposit	2023-12-08
4500	1650	33.00	withdrawal	2024-01-27
4501	1513	365.40	deposit	2024-04-08
4502	1734	392.50	deposit	2024-01-29
4503	568	345.60	withdrawal	2023-08-14
4504	618	438.40	deposit	2024-05-24
4505	13	132.50	withdrawal	2023-09-20
4506	299	244.60	deposit	2024-03-16
4507	352	372.20	withdrawal	2023-02-09
4508	519	187.50	withdrawal	2024-02-04
4509	954	86.60	deposit	2023-07-08
4510	1501	150.00	withdrawal	2023-05-21
4511	904	380.10	deposit	2023-11-22
4512	128	233.30	withdrawal	2023-01-12
4513	1094	174.20	withdrawal	2024-01-14
4514	1671	187.90	withdrawal	2023-10-21
4515	1448	323.00	deposit	2023-04-05
4516	1205	424.80	deposit	2023-04-04
4517	515	132.80	withdrawal	2023-07-10
4518	893	128.40	deposit	2024-04-11
4519	425	361.30	deposit	2023-02-06
4520	761	146.40	deposit	2024-01-30
4521	42	162.50	deposit	2024-01-10
4522	1378	222.00	deposit	2023-08-25
4523	1133	387.60	deposit	2023-03-01
4524	1014	17.70	deposit	2023-09-13
4525	1634	334.00	deposit	2023-09-18
4526	777	429.90	withdrawal	2024-04-14
4527	1464	493.00	deposit	2023-06-22
4528	1055	152.50	deposit	2023-11-20
4529	776	356.30	withdrawal	2023-12-21
4530	420	427.60	deposit	2023-09-13
4531	1517	130.70	deposit	2023-12-23
4532	88	132.80	withdrawal	2024-01-19
4533	964	419.10	deposit	2024-04-02
4534	380	276.50	deposit	2023-10-04
4535	611	109.60	deposit	2023-06-12
4536	132	120.70	withdrawal	2023-05-13
4537	1441	195.60	withdrawal	2023-08-16
4538	1237	449.00	deposit	2023-08-06
4539	1102	381.90	deposit	2023-12-19
4540	231	105.70	deposit	2023-05-18
4541	1620	112.40	withdrawal	2023-02-15
4542	462	345.30	deposit	2023-03-08
4543	125	483.80	deposit	2024-03-31
4544	246	315.80	withdrawal	2023-02-05
4545	1136	469.20	withdrawal	2024-01-23
4546	385	240.10	deposit	2023-10-21
4547	17	336.10	deposit	2023-05-03
4548	1446	166.70	withdrawal	2023-12-15
4549	395	25.90	deposit	2023-04-09
4550	387	388.40	withdrawal	2023-11-26
4551	327	419.40	withdrawal	2023-08-22
4552	248	301.30	withdrawal	2023-03-12
4553	765	146.80	deposit	2023-01-25
4554	1671	285.40	withdrawal	2024-02-11
4555	41	23.30	withdrawal	2023-05-12
4556	933	417.40	deposit	2023-10-09
4557	1539	494.50	deposit	2023-07-14
4558	1037	437.40	deposit	2023-10-08
4559	1705	307.30	deposit	2023-10-11
4560	1561	269.10	deposit	2023-06-14
4561	1476	263.40	deposit	2023-10-04
4562	564	269.40	withdrawal	2024-02-10
4563	1206	486.40	deposit	2023-05-13
4564	422	152.60	deposit	2023-09-11
4565	1650	454.50	deposit	2023-02-16
4566	1611	430.20	deposit	2023-05-28
4567	1248	119.60	deposit	2024-05-10
4568	1384	234.10	withdrawal	2023-12-30
4569	593	250.10	withdrawal	2023-12-15
4570	776	156.30	deposit	2023-11-04
4571	681	481.40	withdrawal	2023-10-14
4572	1015	172.60	withdrawal	2023-10-12
4573	629	422.10	withdrawal	2023-04-04
4574	999	225.80	deposit	2023-02-26
4575	735	320.80	deposit	2023-03-23
4576	85	334.40	withdrawal	2024-04-29
4577	1507	75.60	withdrawal	2023-01-23
4578	70	26.50	withdrawal	2023-01-23
4579	1366	279.80	withdrawal	2024-05-18
4580	1244	384.90	withdrawal	2023-01-24
4581	98	421.70	deposit	2023-12-14
4582	1108	197.90	deposit	2023-12-07
4583	1071	467.50	withdrawal	2024-01-04
4584	971	274.30	deposit	2023-11-23
4585	1259	63.10	deposit	2023-03-23
4586	995	246.20	withdrawal	2024-04-22
4587	12	129.60	withdrawal	2024-02-24
4588	308	474.40	withdrawal	2023-01-15
4589	482	300.40	withdrawal	2023-09-06
4590	1160	256.40	withdrawal	2023-01-27
4591	1453	332.80	withdrawal	2023-01-10
4592	1793	128.50	withdrawal	2023-09-08
4593	1135	269.80	deposit	2024-04-21
4594	921	312.20	withdrawal	2024-02-21
4595	408	484.70	withdrawal	2023-02-03
4596	787	333.90	deposit	2023-07-01
4597	1305	37.50	withdrawal	2024-02-19
4598	1656	433.70	withdrawal	2024-03-02
4599	1062	52.60	withdrawal	2023-03-14
4600	1653	309.60	deposit	2023-01-07
4601	638	298.80	withdrawal	2024-03-29
4602	1662	220.00	deposit	2024-04-29
4603	1494	164.10	withdrawal	2023-12-22
4604	249	441.70	withdrawal	2023-02-26
4605	761	390.50	deposit	2024-05-18
4606	239	362.70	withdrawal	2023-11-28
4607	1643	455.30	withdrawal	2024-02-13
4608	1270	293.00	deposit	2023-09-30
4609	1665	475.20	deposit	2023-08-10
4610	1290	96.50	withdrawal	2024-05-09
4611	864	80.90	deposit	2023-09-28
4612	780	145.40	deposit	2023-12-18
4613	347	10.00	withdrawal	2023-07-02
4614	31	213.70	deposit	2024-02-20
4615	977	28.10	withdrawal	2023-07-13
4616	801	441.10	withdrawal	2024-01-25
4617	1283	50.80	withdrawal	2023-11-10
4618	302	359.50	deposit	2023-04-20
4619	492	32.30	deposit	2023-12-25
4620	98	116.00	deposit	2023-01-18
4621	1337	91.10	deposit	2023-01-13
4622	485	157.40	deposit	2023-06-27
4623	877	119.90	withdrawal	2024-02-11
4624	914	273.90	deposit	2023-05-12
4625	913	429.30	deposit	2023-11-03
4626	1394	281.10	deposit	2023-01-15
4627	810	210.90	deposit	2023-09-29
4628	785	80.20	withdrawal	2024-04-07
4629	1713	182.00	deposit	2023-03-23
4630	1113	416.00	withdrawal	2023-03-27
4631	955	50.80	deposit	2024-01-16
4632	1659	363.50	deposit	2024-03-27
4633	1382	344.40	deposit	2024-05-07
4634	117	301.30	withdrawal	2023-02-26
4635	1089	112.70	deposit	2023-12-13
4636	419	376.70	deposit	2023-05-20
4637	1705	226.00	deposit	2023-08-02
4638	1236	252.00	deposit	2024-05-21
4639	1319	369.20	withdrawal	2023-12-24
4640	680	478.70	deposit	2023-05-17
4641	710	74.50	withdrawal	2023-02-07
4642	1421	374.00	deposit	2024-03-01
4643	1683	291.40	deposit	2024-01-27
4644	1451	463.10	withdrawal	2023-05-06
4645	1706	402.50	withdrawal	2023-11-19
4646	1650	118.60	withdrawal	2023-10-04
4647	298	114.70	deposit	2024-02-15
4648	1516	71.70	deposit	2023-01-18
4649	538	100.50	withdrawal	2023-04-07
4650	1338	499.40	deposit	2023-03-03
4651	176	382.00	withdrawal	2023-03-02
4652	1743	259.70	deposit	2023-11-20
4653	898	308.80	withdrawal	2023-11-11
4654	1123	382.70	withdrawal	2023-08-24
4655	1693	398.10	deposit	2023-01-12
4656	75	31.80	deposit	2023-06-19
4657	521	203.50	deposit	2024-02-20
4658	1108	38.20	withdrawal	2024-02-06
4659	588	406.40	withdrawal	2024-01-07
4660	222	438.70	deposit	2023-06-07
4661	1748	393.60	withdrawal	2024-04-06
4662	579	321.50	withdrawal	2024-04-27
4663	1367	36.30	deposit	2024-02-08
4664	1006	133.80	deposit	2023-05-14
4665	1668	156.20	withdrawal	2023-06-02
4666	1404	10.10	deposit	2024-04-02
4667	1250	274.50	deposit	2023-10-10
4668	167	277.70	withdrawal	2023-08-01
4669	1723	398.90	deposit	2023-01-20
4670	1209	488.90	withdrawal	2024-05-01
4671	697	393.60	withdrawal	2023-05-02
4672	51	415.40	deposit	2024-03-25
4673	1551	52.40	deposit	2023-08-16
4674	1074	199.00	withdrawal	2023-08-17
4675	299	325.20	deposit	2023-03-27
4676	1536	73.60	withdrawal	2024-03-22
4677	1758	136.60	withdrawal	2023-02-28
4678	1258	97.10	withdrawal	2024-05-12
4679	1711	307.40	withdrawal	2024-04-03
4680	606	139.70	deposit	2023-08-12
4681	235	327.90	deposit	2023-02-12
4682	574	204.10	withdrawal	2023-07-13
4683	560	81.10	withdrawal	2024-04-04
4684	358	248.30	withdrawal	2023-01-20
4685	765	248.40	deposit	2023-02-19
4686	357	165.40	withdrawal	2023-02-02
4687	694	369.40	withdrawal	2024-05-31
4688	852	161.60	withdrawal	2023-02-25
4689	817	447.20	withdrawal	2023-08-15
4690	1350	149.30	withdrawal	2023-03-28
4691	1607	369.20	withdrawal	2024-02-07
4692	558	212.40	deposit	2024-01-03
4693	318	98.90	withdrawal	2023-04-10
4694	1421	316.40	withdrawal	2023-08-19
4695	295	449.40	withdrawal	2023-05-21
4696	1572	281.90	withdrawal	2023-09-25
4697	887	23.00	deposit	2023-04-20
4698	1170	321.80	deposit	2023-01-08
4699	99	435.00	deposit	2023-11-30
4700	1242	475.20	withdrawal	2023-05-12
4701	160	201.10	deposit	2023-01-19
4702	52	299.70	withdrawal	2023-03-14
4703	770	163.20	withdrawal	2023-08-17
4704	1717	117.00	withdrawal	2023-07-23
5051	470	332.80	deposit	2024-04-28
4705	1055	159.90	withdrawal	2023-09-18
4706	1533	101.00	withdrawal	2024-04-10
4707	915	18.90	deposit	2023-10-14
4708	1753	25.30	deposit	2023-06-26
4709	978	246.20	deposit	2024-03-03
4710	215	282.70	deposit	2023-07-22
4711	1185	190.90	deposit	2023-06-25
4712	1159	67.30	deposit	2023-05-21
4713	896	282.10	withdrawal	2023-12-24
4714	1460	223.30	deposit	2023-10-11
4715	789	266.40	withdrawal	2024-05-23
4716	920	175.00	withdrawal	2023-02-14
4717	1063	459.90	withdrawal	2023-12-05
4718	1742	415.20	withdrawal	2023-04-15
4719	572	317.10	deposit	2023-06-18
4720	1292	459.10	withdrawal	2024-05-03
4721	139	399.40	withdrawal	2023-09-03
4722	936	124.90	withdrawal	2023-12-11
4723	293	63.10	deposit	2023-12-21
4724	1372	46.00	deposit	2023-03-05
4725	69	186.80	deposit	2023-07-22
4726	99	448.90	withdrawal	2023-11-07
4727	953	333.20	withdrawal	2024-05-07
4728	1270	83.60	withdrawal	2023-06-06
4729	1531	231.10	withdrawal	2023-03-11
4730	63	479.90	deposit	2023-08-29
4731	864	39.50	withdrawal	2023-07-28
4732	179	18.30	deposit	2023-04-16
4733	103	374.60	withdrawal	2023-01-14
4734	1503	306.60	deposit	2023-06-21
4735	1110	223.10	deposit	2024-03-15
4736	122	113.70	deposit	2024-02-17
4737	1404	268.30	deposit	2023-04-15
4738	657	169.90	withdrawal	2023-03-24
4739	1532	406.90	withdrawal	2023-01-15
4740	223	129.60	withdrawal	2024-01-21
4741	1413	303.30	deposit	2023-12-10
4742	449	483.70	withdrawal	2023-07-08
4743	1058	230.80	deposit	2024-05-19
4744	678	104.60	deposit	2024-01-11
4745	1063	399.30	deposit	2024-04-03
4746	1469	372.60	withdrawal	2023-04-16
4747	198	327.00	withdrawal	2023-09-14
4748	503	409.60	withdrawal	2024-04-20
4749	711	289.60	deposit	2023-09-09
4750	977	91.50	deposit	2023-11-22
4751	215	194.00	withdrawal	2024-03-01
4752	274	266.80	deposit	2023-06-30
4753	1746	290.00	deposit	2023-01-15
4754	1765	351.40	withdrawal	2023-04-09
4755	542	407.90	deposit	2024-04-10
4756	14	80.10	deposit	2024-01-06
4757	872	172.20	deposit	2023-03-20
4758	369	91.70	deposit	2023-08-18
4759	1158	14.60	withdrawal	2024-04-03
4760	39	8.30	withdrawal	2023-09-06
4761	1094	57.90	deposit	2024-05-29
4762	1153	217.50	withdrawal	2024-04-01
4763	551	62.30	withdrawal	2023-11-08
4764	337	15.00	deposit	2023-03-13
4765	1684	298.60	withdrawal	2024-03-31
4766	697	137.90	withdrawal	2023-06-06
4767	920	341.70	withdrawal	2023-06-03
4768	1746	49.80	deposit	2023-08-10
4769	1577	393.40	withdrawal	2024-05-14
4770	1109	180.70	deposit	2023-02-12
4771	1375	148.00	deposit	2023-11-17
4772	219	362.40	deposit	2024-03-31
4773	633	229.10	deposit	2023-03-21
4774	1218	169.50	withdrawal	2023-02-25
4775	1203	208.10	withdrawal	2023-09-05
4776	942	215.30	deposit	2023-02-11
4777	511	31.90	withdrawal	2024-01-01
4778	1104	196.80	deposit	2023-08-01
4779	81	222.30	withdrawal	2023-10-31
4780	76	392.20	deposit	2023-05-06
4781	1378	385.30	withdrawal	2024-04-28
4782	1212	255.90	deposit	2023-12-27
4783	228	165.30	deposit	2023-01-03
4784	821	104.20	deposit	2024-01-04
4785	77	287.40	withdrawal	2023-07-02
4786	933	232.60	deposit	2023-11-26
4787	893	207.10	withdrawal	2023-02-03
4788	1643	235.60	withdrawal	2023-09-12
4789	1633	8.90	deposit	2024-01-25
4790	444	356.00	deposit	2023-10-21
4791	1203	126.50	withdrawal	2024-03-22
4792	953	260.00	deposit	2024-05-03
4793	1123	163.60	withdrawal	2023-02-08
4794	212	39.70	withdrawal	2023-01-13
4795	177	186.00	deposit	2024-02-07
4796	951	155.80	deposit	2024-04-20
4797	545	180.80	withdrawal	2023-09-04
4798	1254	155.40	withdrawal	2024-01-13
4799	1483	354.60	deposit	2023-09-06
4800	492	156.20	deposit	2023-11-01
4801	1028	330.90	withdrawal	2024-03-20
4802	1360	273.80	withdrawal	2023-10-03
4803	1502	322.20	deposit	2023-12-10
4804	691	470.80	withdrawal	2024-05-22
4805	1768	283.20	withdrawal	2023-09-08
4806	964	452.70	withdrawal	2023-03-03
4807	630	170.40	deposit	2023-11-19
4808	226	159.20	deposit	2023-08-01
4809	1299	284.30	deposit	2023-02-25
4810	459	283.90	deposit	2024-02-10
4811	291	368.50	deposit	2023-01-01
4812	665	142.70	deposit	2023-07-27
4813	170	155.30	deposit	2023-07-22
4814	982	265.00	deposit	2023-09-17
4815	1115	500.60	deposit	2023-08-25
4816	349	414.40	withdrawal	2023-12-10
4817	166	197.20	deposit	2024-05-09
4818	847	160.50	deposit	2023-03-20
4819	219	281.70	withdrawal	2023-04-13
4820	695	201.60	withdrawal	2023-04-20
4821	254	180.60	deposit	2023-02-13
4822	322	339.30	deposit	2023-01-16
4823	1367	316.50	withdrawal	2024-05-20
4824	708	255.70	withdrawal	2023-02-27
4825	1399	143.80	deposit	2023-02-09
4826	1663	288.70	withdrawal	2023-10-07
4827	806	44.30	deposit	2023-10-27
4828	351	415.40	withdrawal	2023-10-18
4829	870	357.10	withdrawal	2023-03-27
4830	1613	352.90	deposit	2023-01-18
4831	381	470.60	withdrawal	2023-03-06
4832	1352	440.40	deposit	2024-05-12
4833	1383	346.40	deposit	2023-10-05
4834	669	450.20	withdrawal	2024-04-02
4835	704	97.90	withdrawal	2023-03-12
4836	692	201.60	withdrawal	2023-05-28
4837	1507	30.30	deposit	2023-06-03
4838	1680	324.30	withdrawal	2024-01-14
4839	785	419.80	deposit	2024-01-08
4840	1234	26.40	deposit	2023-09-16
4841	680	214.70	deposit	2023-07-27
4842	1512	184.10	withdrawal	2023-07-30
4843	869	125.00	deposit	2023-08-09
4844	95	188.90	deposit	2024-01-02
4845	1367	211.80	deposit	2023-05-27
4846	816	329.40	deposit	2024-02-17
4847	497	340.30	deposit	2023-02-13
4848	354	397.70	deposit	2023-12-31
4849	781	498.80	deposit	2024-03-03
4850	204	62.00	withdrawal	2024-05-05
4851	608	246.90	deposit	2023-05-17
4852	687	379.60	deposit	2024-02-24
4853	1469	12.00	withdrawal	2023-08-12
4854	1247	48.10	withdrawal	2024-02-14
4855	1415	34.50	withdrawal	2023-11-14
4856	522	327.80	withdrawal	2023-01-04
4857	813	358.70	deposit	2024-04-04
4858	1113	197.80	deposit	2024-01-14
4859	248	195.10	withdrawal	2024-05-19
4860	650	170.00	deposit	2023-06-01
4861	281	496.20	deposit	2023-12-08
4862	788	440.80	deposit	2023-02-04
4863	1612	66.30	deposit	2023-01-27
4864	673	402.50	deposit	2024-02-03
4865	1031	297.40	withdrawal	2023-04-17
4866	1054	481.10	withdrawal	2023-09-23
4867	822	66.50	deposit	2023-03-02
4868	282	198.40	withdrawal	2023-01-24
4869	1600	254.00	deposit	2023-06-12
4870	826	102.10	withdrawal	2024-01-15
4871	1219	35.20	deposit	2023-10-26
4872	1023	331.00	deposit	2024-05-07
4873	32	290.50	deposit	2024-01-31
4874	867	61.60	deposit	2024-04-02
4875	216	34.20	withdrawal	2023-01-09
4876	1506	211.50	withdrawal	2024-01-11
4877	1717	382.30	withdrawal	2024-02-28
4878	159	376.60	withdrawal	2023-02-14
4879	640	415.80	deposit	2024-01-21
4880	1386	455.80	withdrawal	2023-12-31
4881	802	231.40	deposit	2023-05-09
4882	1616	232.80	withdrawal	2023-07-22
4883	292	471.60	withdrawal	2023-01-17
4884	738	176.70	withdrawal	2023-04-18
4885	501	32.50	withdrawal	2023-12-28
4886	1091	448.40	withdrawal	2023-12-20
4887	33	350.80	deposit	2023-05-18
4888	276	207.70	deposit	2023-10-19
4889	1050	300.20	deposit	2023-12-29
4890	1053	439.80	withdrawal	2023-07-02
4891	840	339.20	withdrawal	2023-05-11
4892	1280	268.80	withdrawal	2023-07-09
4893	1464	489.90	deposit	2023-11-14
4894	66	187.20	withdrawal	2023-02-03
4895	310	433.90	deposit	2024-01-26
4896	1167	486.90	deposit	2023-12-06
4897	859	367.80	deposit	2024-03-30
4898	1642	485.80	withdrawal	2024-04-22
4899	280	5.60	withdrawal	2023-11-06
4900	653	360.60	deposit	2023-08-17
4901	1317	418.30	deposit	2024-04-30
4902	718	197.50	deposit	2024-01-11
4903	451	342.20	deposit	2024-02-25
4904	1355	59.60	withdrawal	2023-06-13
4905	956	413.70	withdrawal	2023-05-13
4906	1758	482.50	deposit	2023-06-06
4907	1689	446.10	withdrawal	2023-05-27
4908	1469	50.10	deposit	2023-05-17
4909	1428	475.20	deposit	2023-11-15
4910	560	323.90	withdrawal	2024-01-14
4911	1285	114.60	deposit	2023-01-01
4912	646	233.00	deposit	2024-02-06
4913	1315	155.00	withdrawal	2023-03-08
4914	352	95.80	withdrawal	2023-12-08
4915	595	495.80	deposit	2023-05-21
4916	472	111.20	deposit	2023-05-15
4917	222	71.90	withdrawal	2024-01-08
4918	187	22.40	withdrawal	2023-05-13
4919	154	421.10	deposit	2023-12-25
4920	1204	59.00	deposit	2023-07-02
4921	1776	69.80	deposit	2023-10-10
4922	1667	30.20	deposit	2023-04-18
4923	1398	254.10	deposit	2023-08-05
4924	118	287.20	deposit	2023-09-09
4925	558	127.20	withdrawal	2023-03-26
4926	1463	36.30	deposit	2023-05-26
4927	1087	293.40	deposit	2024-01-23
4928	827	150.80	withdrawal	2023-08-06
4929	1054	448.80	deposit	2023-03-17
4930	1382	422.50	deposit	2023-01-23
4931	1499	457.40	deposit	2023-07-01
4932	1205	235.00	withdrawal	2024-04-20
4933	762	472.90	deposit	2024-02-28
4934	297	386.70	deposit	2023-09-24
4935	489	58.90	withdrawal	2024-02-03
4936	499	329.30	withdrawal	2023-12-03
4937	539	171.30	withdrawal	2023-08-22
4938	162	479.60	deposit	2023-02-09
4939	198	440.10	withdrawal	2024-05-19
4940	111	215.20	withdrawal	2023-01-02
4941	587	291.10	deposit	2024-02-03
4942	94	248.30	deposit	2023-05-07
4943	645	185.40	deposit	2023-01-27
4944	25	89.80	withdrawal	2023-06-09
4945	1307	321.00	deposit	2023-02-01
4946	1323	343.00	deposit	2023-12-02
4947	1389	42.80	deposit	2023-03-28
4948	289	95.90	deposit	2023-07-25
4949	1396	220.00	deposit	2024-02-24
4950	103	121.30	deposit	2023-12-29
4951	6	370.30	withdrawal	2023-04-26
4952	1011	418.20	withdrawal	2024-04-02
4953	293	44.80	deposit	2023-05-04
4954	67	252.30	withdrawal	2023-01-08
4955	1017	13.70	withdrawal	2023-01-17
4956	1755	393.40	deposit	2024-02-21
4957	508	79.60	deposit	2023-10-09
4958	610	402.90	deposit	2023-11-02
4959	270	173.00	deposit	2024-01-22
4960	250	312.90	withdrawal	2023-01-18
4961	1159	358.80	withdrawal	2024-01-24
4962	1211	263.10	deposit	2023-07-11
4963	1054	268.30	withdrawal	2023-11-22
4964	527	122.20	deposit	2023-09-09
4965	1101	321.00	withdrawal	2024-01-20
4966	843	204.80	deposit	2023-01-04
4967	1188	25.20	deposit	2023-08-08
4968	1766	178.50	deposit	2023-09-28
4969	1018	256.80	withdrawal	2023-01-18
4970	1171	114.60	deposit	2024-01-17
4971	384	187.70	deposit	2023-09-10
4972	1617	235.90	withdrawal	2023-10-29
4973	567	164.00	withdrawal	2023-07-14
4974	681	342.70	withdrawal	2024-02-18
4975	1300	327.20	deposit	2023-01-30
4976	34	308.40	deposit	2023-06-12
4977	678	442.40	withdrawal	2023-12-04
4978	1521	368.60	deposit	2023-06-09
4979	413	167.90	deposit	2023-06-19
4980	1287	450.80	deposit	2024-05-24
4981	1257	47.10	withdrawal	2024-03-03
4982	1437	402.40	deposit	2023-02-12
4983	1092	428.90	deposit	2024-04-19
4984	515	348.60	withdrawal	2023-05-13
4985	175	38.20	deposit	2023-09-05
4986	434	89.90	withdrawal	2023-08-29
4987	687	387.20	withdrawal	2023-10-08
4988	29	431.30	withdrawal	2024-05-16
4989	773	211.60	deposit	2023-01-19
4990	177	177.20	deposit	2023-09-02
4991	1706	299.40	deposit	2023-11-03
4992	1146	316.00	withdrawal	2024-02-28
4993	983	52.90	withdrawal	2023-06-25
4994	97	394.10	withdrawal	2023-08-04
4995	525	14.80	deposit	2023-06-01
4996	683	224.50	deposit	2023-07-25
4997	729	19.50	deposit	2023-10-03
4998	894	276.20	deposit	2023-04-22
4999	1697	449.50	withdrawal	2023-01-14
5000	862	146.30	deposit	2024-01-01
5001	841	225.00	withdrawal	2023-08-24
5002	176	389.20	withdrawal	2023-08-09
5003	1201	400.40	withdrawal	2024-05-20
5004	384	408.00	withdrawal	2023-12-18
5005	409	36.70	deposit	2023-03-19
5006	1386	458.40	withdrawal	2023-10-13
5007	285	304.00	deposit	2023-03-02
5008	1511	391.10	withdrawal	2024-03-05
5009	119	364.30	withdrawal	2023-04-25
5010	256	6.20	withdrawal	2023-03-17
5011	689	485.50	withdrawal	2023-06-18
5012	156	27.70	withdrawal	2024-05-10
5013	500	184.20	withdrawal	2023-02-05
5014	377	170.50	withdrawal	2024-04-07
5015	848	31.30	withdrawal	2023-09-25
5016	480	432.50	deposit	2023-10-03
5017	1005	280.70	withdrawal	2023-02-22
5018	1364	460.80	withdrawal	2023-08-23
5019	431	139.10	deposit	2023-05-16
5020	359	334.40	deposit	2023-07-03
5021	385	12.40	withdrawal	2023-08-31
5022	457	332.80	deposit	2023-09-16
5023	797	460.60	withdrawal	2023-09-13
5024	525	18.00	deposit	2023-07-22
5025	1725	18.10	withdrawal	2023-02-24
5026	767	277.10	deposit	2023-12-30
5027	1639	186.60	deposit	2023-05-14
5028	1320	376.80	withdrawal	2024-01-17
5029	258	278.70	withdrawal	2024-01-10
5030	1048	351.40	withdrawal	2024-03-02
5031	29	478.70	withdrawal	2023-01-21
5032	1049	288.70	withdrawal	2024-01-03
5033	463	126.60	deposit	2023-11-09
5034	3	211.30	deposit	2024-01-16
5035	544	12.30	deposit	2023-06-18
5036	2	336.80	withdrawal	2024-04-14
5037	1554	91.60	deposit	2023-08-21
5038	425	73.00	withdrawal	2023-12-29
5039	664	286.00	withdrawal	2023-01-13
5040	1543	321.60	withdrawal	2023-05-16
5041	1112	86.30	deposit	2023-05-17
5042	79	145.70	withdrawal	2023-10-07
5043	1309	216.10	deposit	2024-02-06
5044	295	264.70	withdrawal	2024-05-13
5045	1716	91.50	deposit	2023-09-27
5046	1550	61.00	deposit	2023-05-18
5047	1243	276.10	withdrawal	2023-11-08
5048	301	146.20	withdrawal	2023-01-09
5049	116	182.30	withdrawal	2024-01-17
5050	1768	203.20	deposit	2024-02-02
5052	212	403.40	withdrawal	2024-03-14
5053	1381	333.00	withdrawal	2024-02-23
5054	725	442.80	withdrawal	2023-02-20
5055	1435	411.20	withdrawal	2023-02-26
5056	405	460.00	deposit	2023-12-25
5057	1033	152.30	withdrawal	2024-02-27
5058	1024	382.80	deposit	2023-07-07
5059	1117	289.00	withdrawal	2023-06-11
5060	1372	219.70	withdrawal	2024-01-07
5061	1002	80.80	withdrawal	2024-04-29
5062	810	282.40	deposit	2023-06-21
5063	544	492.90	deposit	2023-12-26
5064	521	479.30	deposit	2023-10-03
5065	478	265.20	deposit	2023-01-13
5066	926	372.20	deposit	2024-02-07
5067	240	54.70	deposit	2023-04-30
5068	783	448.00	deposit	2024-04-23
5069	820	163.50	deposit	2023-08-19
5070	852	267.40	withdrawal	2024-03-08
5071	750	291.50	withdrawal	2023-10-03
5072	14	336.10	deposit	2023-07-28
5073	498	340.70	deposit	2023-10-17
5074	1597	455.40	withdrawal	2024-01-21
5075	427	390.00	deposit	2023-09-29
5076	112	441.70	withdrawal	2023-06-09
5077	711	59.40	withdrawal	2023-08-06
5078	57	321.10	withdrawal	2023-10-26
5079	178	22.60	deposit	2023-01-25
5080	320	70.60	deposit	2023-06-07
5081	1112	266.50	withdrawal	2024-04-16
5082	1509	338.70	withdrawal	2024-04-18
5083	959	313.80	deposit	2023-01-15
5084	1390	92.00	deposit	2024-03-27
5085	373	461.40	withdrawal	2023-07-01
5086	578	260.40	deposit	2023-04-27
5087	775	290.70	deposit	2023-06-09
5088	1201	370.40	deposit	2023-01-22
5089	1714	462.60	deposit	2023-05-19
5090	1112	290.50	withdrawal	2023-06-11
5091	551	270.30	withdrawal	2024-04-17
5092	1667	243.80	withdrawal	2023-08-05
5093	128	51.50	deposit	2024-04-20
5094	834	58.70	deposit	2023-06-09
5095	259	205.00	deposit	2023-03-22
5096	1730	32.70	withdrawal	2023-09-19
5097	448	188.70	withdrawal	2023-03-18
5098	1483	438.20	withdrawal	2023-11-18
5099	1089	17.50	deposit	2023-05-30
5100	1759	131.40	withdrawal	2024-04-13
5101	1216	199.40	deposit	2023-04-08
5102	1373	145.70	deposit	2023-06-01
5103	1424	420.40	deposit	2023-09-04
5104	1185	302.10	withdrawal	2024-02-13
5105	510	404.80	deposit	2023-02-22
5106	520	177.10	deposit	2023-12-02
5107	426	37.30	deposit	2023-02-19
5108	425	64.60	withdrawal	2023-07-28
5109	663	219.10	withdrawal	2023-09-04
5110	644	228.30	deposit	2023-08-23
5111	1788	258.80	deposit	2023-09-30
5112	1784	266.80	withdrawal	2024-02-27
5113	847	117.40	deposit	2023-09-22
5114	1517	402.80	withdrawal	2023-07-19
5115	92	85.40	withdrawal	2024-05-25
5116	1667	484.60	withdrawal	2024-01-15
5117	1721	298.00	deposit	2024-01-08
5118	1768	370.90	deposit	2023-06-02
5119	1402	61.00	withdrawal	2024-03-17
5120	1540	493.10	withdrawal	2023-01-03
5121	902	319.50	withdrawal	2023-10-01
5122	641	392.90	deposit	2023-06-23
5123	745	177.20	withdrawal	2023-03-17
5124	59	185.10	withdrawal	2023-04-19
5125	1147	206.80	withdrawal	2023-02-09
5126	483	54.00	deposit	2023-06-04
5127	17	22.00	withdrawal	2023-11-07
5128	363	189.20	withdrawal	2023-09-14
5129	1165	92.30	withdrawal	2023-04-02
5130	724	261.30	withdrawal	2023-09-23
5131	1590	52.60	deposit	2023-12-02
5132	426	303.80	deposit	2023-06-24
5133	686	66.60	withdrawal	2024-03-29
5134	1332	153.70	withdrawal	2023-08-13
5135	667	241.40	deposit	2024-03-17
5136	1162	360.40	deposit	2024-05-24
5137	698	448.00	deposit	2023-09-20
5138	254	352.80	withdrawal	2023-06-24
5139	480	394.90	deposit	2024-04-27
5140	680	208.60	withdrawal	2023-04-23
5141	13	29.00	deposit	2023-12-03
5142	1463	148.70	deposit	2023-12-23
5143	141	494.10	withdrawal	2023-12-30
5144	1392	183.70	withdrawal	2023-10-03
5145	442	251.60	deposit	2024-04-21
5146	269	75.60	withdrawal	2023-01-19
5147	1303	69.00	withdrawal	2023-05-09
5148	1518	196.50	withdrawal	2023-04-23
5149	1499	59.60	deposit	2023-08-17
5150	292	69.60	withdrawal	2023-07-01
5151	1140	314.20	withdrawal	2023-01-31
5152	269	237.90	withdrawal	2023-08-23
5153	1285	191.80	deposit	2023-06-14
5154	1144	235.00	deposit	2023-04-24
5155	1293	112.40	withdrawal	2023-11-19
5156	1769	466.00	deposit	2023-11-06
5157	1561	357.60	withdrawal	2023-10-31
5158	1610	262.40	deposit	2023-05-07
5159	528	17.00	deposit	2023-08-05
5160	907	378.00	withdrawal	2023-11-17
5161	519	328.40	deposit	2024-03-23
5162	360	334.00	withdrawal	2023-06-11
5163	1174	124.40	withdrawal	2023-12-03
5164	1361	80.70	deposit	2024-03-27
5165	1091	178.60	withdrawal	2023-04-12
5166	614	45.20	withdrawal	2023-04-29
5167	210	285.40	deposit	2023-02-09
5168	105	153.50	deposit	2024-01-23
5169	635	258.20	deposit	2023-05-15
5170	1785	131.40	withdrawal	2024-04-11
5171	536	499.20	deposit	2023-06-22
5172	1773	363.40	deposit	2024-05-18
5173	1474	246.30	withdrawal	2023-06-05
5174	1042	431.70	withdrawal	2023-06-26
5175	912	232.40	deposit	2023-04-15
5176	781	216.70	withdrawal	2023-10-18
5177	1292	474.80	withdrawal	2023-11-15
5178	733	316.80	withdrawal	2023-08-22
5179	1787	42.20	withdrawal	2023-08-01
5180	1046	10.60	deposit	2023-03-14
5181	141	456.10	deposit	2024-04-29
5182	712	151.50	deposit	2023-04-02
5183	1413	452.30	withdrawal	2023-07-03
5184	311	494.30	withdrawal	2023-03-22
5185	1349	428.60	deposit	2023-11-01
5186	1289	308.90	withdrawal	2023-07-18
5187	260	434.40	withdrawal	2023-09-09
5188	1291	70.00	deposit	2024-02-05
5189	661	280.60	deposit	2023-07-24
5190	191	416.20	withdrawal	2023-08-11
5191	743	490.60	deposit	2023-06-24
5192	1470	294.30	deposit	2023-11-29
5193	1563	400.80	deposit	2024-01-11
5194	1581	90.80	deposit	2023-11-08
5195	456	157.10	withdrawal	2023-05-22
5196	632	335.60	deposit	2023-06-16
5197	966	242.10	deposit	2023-05-28
5198	1345	146.70	deposit	2024-01-07
5199	488	440.10	withdrawal	2023-12-26
5200	757	192.60	deposit	2023-12-12
5201	614	89.80	withdrawal	2023-10-24
5202	897	67.10	deposit	2023-11-01
5203	291	104.60	withdrawal	2023-04-21
5204	446	286.60	withdrawal	2023-06-01
5205	509	155.70	deposit	2024-05-24
5206	1059	213.50	withdrawal	2023-05-14
5207	908	94.00	deposit	2024-01-14
5208	1667	96.90	deposit	2023-05-01
5209	806	320.40	deposit	2023-10-05
5210	565	127.40	deposit	2023-05-31
5211	1163	467.40	deposit	2023-06-18
5212	59	485.40	withdrawal	2023-01-16
5213	831	206.30	withdrawal	2023-05-17
5214	1669	487.10	withdrawal	2023-12-15
5215	1716	419.90	withdrawal	2023-01-31
5216	1182	239.10	withdrawal	2023-01-01
5217	1607	301.60	deposit	2023-07-08
5218	1565	241.30	deposit	2023-12-02
5219	389	104.20	withdrawal	2023-01-09
5220	1694	158.90	deposit	2023-09-06
5221	512	187.90	withdrawal	2024-02-18
5222	882	201.50	deposit	2023-06-17
5223	1623	80.60	deposit	2023-01-29
5224	208	167.40	deposit	2023-10-08
5225	925	246.10	deposit	2023-03-04
5226	1026	254.60	deposit	2023-07-05
5227	276	189.90	withdrawal	2023-02-16
5228	1116	114.40	withdrawal	2023-12-03
5229	1559	204.70	withdrawal	2023-05-16
5230	690	455.50	deposit	2024-03-16
5231	270	8.50	deposit	2023-03-22
5232	1094	381.30	withdrawal	2023-06-23
5233	608	351.10	withdrawal	2024-01-20
5234	951	150.60	withdrawal	2023-06-04
5235	1586	221.50	deposit	2023-09-26
5236	675	6.70	withdrawal	2023-04-21
5237	1521	47.20	deposit	2023-09-10
5238	302	415.50	withdrawal	2023-02-13
5239	493	25.00	deposit	2023-12-03
5240	1010	90.10	withdrawal	2023-07-16
5241	716	62.00	deposit	2024-03-22
5242	19	329.40	deposit	2023-04-24
5243	1497	177.80	withdrawal	2024-05-24
5244	1089	336.80	deposit	2023-02-04
5245	1232	315.00	withdrawal	2023-01-12
5246	520	55.20	withdrawal	2023-12-28
5247	76	447.70	deposit	2024-04-12
5248	1661	293.00	deposit	2024-03-05
5249	251	151.50	deposit	2023-08-05
5250	1433	392.60	deposit	2024-03-16
5251	1771	393.40	deposit	2024-05-05
5252	630	97.60	withdrawal	2024-01-09
5253	118	288.70	deposit	2023-04-25
5254	466	25.50	withdrawal	2023-03-22
5255	970	377.30	withdrawal	2024-01-13
5256	12	177.50	withdrawal	2023-03-02
5257	1249	176.70	withdrawal	2023-06-30
5258	1080	422.80	withdrawal	2024-04-14
5259	857	123.40	deposit	2023-10-20
5260	1193	369.30	withdrawal	2024-04-07
5261	1460	151.20	deposit	2023-11-07
5262	15	301.40	withdrawal	2023-03-10
5263	1789	194.40	deposit	2024-03-15
5264	268	455.10	deposit	2023-10-24
5265	1651	8.10	deposit	2023-11-12
5266	1381	397.40	deposit	2023-10-30
5267	1199	124.30	withdrawal	2023-03-28
5268	850	288.20	deposit	2023-09-18
5269	62	256.40	withdrawal	2023-09-22
5270	1213	114.80	withdrawal	2023-07-25
5271	695	397.80	deposit	2023-04-02
5272	95	457.50	deposit	2024-05-22
5273	825	145.50	deposit	2024-05-23
5274	1752	435.50	deposit	2023-10-01
5275	1543	16.00	deposit	2023-06-01
5276	1133	395.20	withdrawal	2024-02-13
5277	1560	396.70	withdrawal	2023-09-30
5278	1464	182.30	withdrawal	2023-04-23
5279	85	25.20	withdrawal	2023-04-05
5280	1613	261.40	withdrawal	2023-12-20
5281	1061	214.90	withdrawal	2023-09-06
5282	576	212.30	withdrawal	2023-10-30
5283	1367	454.00	deposit	2024-01-09
5284	1132	83.90	deposit	2023-10-17
5285	857	434.50	deposit	2024-01-06
5286	111	488.80	deposit	2023-10-23
5287	794	82.50	withdrawal	2023-09-05
5288	1368	433.80	deposit	2024-05-27
5289	450	218.40	withdrawal	2023-05-30
5290	1445	168.70	withdrawal	2023-03-30
5291	515	173.20	deposit	2024-05-08
5292	342	105.40	withdrawal	2024-01-01
5293	271	216.80	withdrawal	2023-05-25
5294	1143	446.30	deposit	2024-02-03
5295	358	389.40	deposit	2023-01-13
5296	1167	291.10	withdrawal	2023-03-02
5297	1620	400.70	withdrawal	2023-09-05
5298	650	70.60	withdrawal	2023-11-12
5299	1541	497.20	withdrawal	2023-11-25
5300	1226	307.20	withdrawal	2023-12-31
5301	628	362.80	withdrawal	2023-04-08
5302	1256	87.10	withdrawal	2024-01-28
5303	456	330.40	deposit	2023-05-13
5304	1364	78.80	withdrawal	2024-01-30
5305	578	114.80	deposit	2024-01-20
5306	66	256.90	withdrawal	2023-01-14
5307	124	153.10	deposit	2023-07-26
5308	1572	379.60	deposit	2023-01-28
5309	694	172.50	withdrawal	2023-05-09
5310	607	229.30	withdrawal	2024-04-26
5311	315	326.10	deposit	2023-03-05
5312	391	14.60	withdrawal	2023-06-16
5313	1525	5.30	withdrawal	2023-02-10
5314	1799	190.90	deposit	2024-04-28
5315	943	234.80	deposit	2023-05-13
5316	729	453.70	deposit	2023-11-25
5317	579	370.90	withdrawal	2023-02-10
5318	751	290.20	withdrawal	2023-01-18
5319	1505	85.30	withdrawal	2023-12-19
5320	1464	32.10	withdrawal	2023-07-20
5321	501	149.40	deposit	2024-03-03
5322	1000	309.20	withdrawal	2023-07-29
5323	55	76.50	deposit	2024-04-10
5324	90	164.90	deposit	2023-11-21
5325	1533	427.10	withdrawal	2023-12-23
5326	1692	58.60	deposit	2023-11-19
5327	301	270.30	deposit	2023-10-26
5328	368	246.90	deposit	2023-05-15
5329	789	463.00	deposit	2024-02-17
5330	1441	365.80	withdrawal	2023-09-06
5331	1088	187.80	deposit	2024-01-13
5332	447	495.40	withdrawal	2023-07-22
5333	1236	108.10	deposit	2023-08-04
5334	1752	134.40	withdrawal	2023-06-10
5335	1487	267.30	deposit	2024-02-14
5336	749	256.30	withdrawal	2023-04-26
5337	667	208.70	withdrawal	2023-07-21
5338	1531	406.20	withdrawal	2023-09-22
5339	174	36.80	withdrawal	2024-03-12
5340	1096	252.70	deposit	2023-03-22
5341	1599	90.70	deposit	2023-02-07
5342	1505	37.50	deposit	2023-08-12
5343	1315	117.00	withdrawal	2023-11-18
5344	1791	397.80	withdrawal	2023-11-23
5345	780	109.30	withdrawal	2024-05-15
5346	536	37.90	withdrawal	2023-11-12
5347	1505	263.80	deposit	2024-02-14
5348	997	312.60	withdrawal	2023-12-09
5349	176	483.10	deposit	2023-10-31
5350	342	404.10	withdrawal	2023-10-04
5351	86	311.70	deposit	2023-07-10
5352	1485	498.50	deposit	2024-01-25
5353	858	257.20	withdrawal	2023-11-17
5354	326	458.00	withdrawal	2024-04-15
5355	1030	446.20	withdrawal	2024-02-20
5356	335	43.10	deposit	2024-04-18
5357	911	139.30	deposit	2023-03-19
5358	8	323.60	deposit	2023-04-18
5359	1075	327.00	withdrawal	2023-04-24
5360	1678	373.70	deposit	2023-11-30
5361	79	392.70	deposit	2024-04-08
5362	430	196.40	withdrawal	2023-01-17
5363	1325	273.50	deposit	2023-12-31
5364	1623	458.80	withdrawal	2023-09-16
5365	906	217.80	withdrawal	2023-07-03
5366	1007	73.60	withdrawal	2023-05-02
5367	739	323.40	withdrawal	2024-04-29
5368	1189	429.30	deposit	2023-07-29
5369	1114	347.90	deposit	2023-10-09
5370	1708	57.50	withdrawal	2023-05-24
5371	1793	123.20	withdrawal	2023-05-23
5372	1202	434.40	deposit	2023-08-26
5373	97	107.30	withdrawal	2023-04-21
5374	1490	265.10	withdrawal	2024-01-23
5375	351	186.90	withdrawal	2024-03-08
5376	529	102.50	withdrawal	2023-06-15
5377	1570	208.10	deposit	2024-05-27
5378	1723	490.10	withdrawal	2023-08-03
5379	205	257.60	withdrawal	2024-05-27
5380	780	150.70	deposit	2023-05-08
5381	358	304.50	withdrawal	2024-02-13
5382	531	81.50	deposit	2023-05-07
5383	926	139.70	withdrawal	2024-02-19
5384	1490	34.00	deposit	2024-01-22
5385	328	113.00	withdrawal	2023-08-28
5386	626	444.40	withdrawal	2023-03-30
5387	1165	298.90	deposit	2024-05-06
5388	1000	74.50	deposit	2023-10-06
5389	1674	165.40	withdrawal	2023-03-12
5390	117	305.40	withdrawal	2023-01-03
5391	905	196.70	deposit	2024-02-17
5392	947	416.60	deposit	2023-03-25
5393	1214	112.20	withdrawal	2024-04-10
5394	1177	70.70	withdrawal	2023-12-23
5395	450	264.20	withdrawal	2023-09-23
5396	1454	167.60	withdrawal	2023-04-23
5397	296	281.00	deposit	2023-09-06
5398	881	244.80	deposit	2023-08-15
5399	585	35.50	deposit	2023-01-21
5400	521	369.50	withdrawal	2023-12-15
5401	154	469.20	withdrawal	2024-03-08
5402	812	360.40	deposit	2024-02-24
5403	1316	300.60	withdrawal	2024-02-09
5404	51	142.90	withdrawal	2023-10-24
5405	1582	145.20	deposit	2024-01-17
5406	370	368.10	withdrawal	2023-04-29
5407	465	391.60	deposit	2023-10-27
5408	1184	31.60	deposit	2023-06-21
5409	228	376.90	withdrawal	2023-10-01
5410	602	455.70	withdrawal	2023-07-06
5411	500	150.20	withdrawal	2023-04-02
5412	665	248.00	withdrawal	2023-10-28
5413	1079	470.80	deposit	2023-03-16
5414	1213	316.60	withdrawal	2023-02-03
5415	846	482.40	withdrawal	2024-03-09
5416	586	300.60	withdrawal	2023-03-13
5417	478	277.00	deposit	2024-03-15
5418	132	380.20	withdrawal	2023-08-19
5419	790	21.70	deposit	2024-01-17
5420	321	61.50	deposit	2023-07-17
5421	1052	247.10	deposit	2023-10-04
5422	1718	441.20	deposit	2023-06-02
5423	325	29.00	withdrawal	2024-01-04
5424	910	436.80	withdrawal	2024-04-28
5425	474	52.60	withdrawal	2024-04-16
5426	28	429.10	deposit	2023-05-31
5427	634	232.80	deposit	2023-07-07
5428	358	43.40	deposit	2023-04-26
5429	902	172.30	deposit	2023-12-07
5430	1085	365.40	withdrawal	2024-02-08
5431	1653	269.70	withdrawal	2023-11-03
5432	1103	396.10	withdrawal	2024-04-22
5433	956	255.60	deposit	2023-02-05
5434	1550	458.70	deposit	2024-03-03
5435	599	95.50	withdrawal	2023-05-04
5436	493	423.60	withdrawal	2024-01-29
5437	654	474.90	deposit	2023-04-02
5438	1607	154.80	withdrawal	2023-04-22
5439	833	263.60	deposit	2023-10-03
5440	1063	375.80	withdrawal	2024-05-05
5441	1101	233.60	withdrawal	2024-03-07
5442	1429	381.60	deposit	2024-04-25
5443	375	387.60	deposit	2023-10-18
5444	1116	489.80	withdrawal	2023-12-06
5445	1432	213.20	withdrawal	2024-04-09
5446	1487	41.80	withdrawal	2023-05-15
5447	618	69.80	deposit	2023-10-24
5448	1361	436.50	deposit	2023-02-23
5449	1130	133.50	deposit	2023-02-23
5450	1503	293.40	deposit	2023-04-25
5451	603	121.50	deposit	2024-04-19
5452	949	156.50	deposit	2023-07-17
5453	1228	17.40	withdrawal	2024-05-08
5454	1533	316.80	withdrawal	2023-07-30
5455	1512	432.10	deposit	2023-06-22
5456	1366	222.70	withdrawal	2023-09-16
5457	1510	273.80	deposit	2024-03-15
5458	20	179.80	deposit	2023-03-24
5459	985	161.50	withdrawal	2024-04-11
5460	1652	241.30	deposit	2024-03-29
5461	93	338.40	deposit	2023-02-11
5462	561	452.80	deposit	2024-01-29
5463	898	354.00	deposit	2023-01-06
5464	911	141.10	deposit	2023-03-08
5465	1172	263.90	withdrawal	2023-02-21
5466	151	74.00	deposit	2023-11-30
5467	575	341.20	withdrawal	2024-03-02
5468	1019	219.40	withdrawal	2023-01-17
5469	904	305.40	withdrawal	2023-12-22
5470	348	93.30	withdrawal	2024-04-28
5471	785	110.90	deposit	2023-12-13
5472	7	240.10	deposit	2024-01-18
5473	907	415.30	withdrawal	2023-01-18
5474	1283	287.80	deposit	2023-06-09
5475	1416	435.10	deposit	2023-02-26
5476	1748	467.80	withdrawal	2024-03-31
5477	1578	341.20	withdrawal	2023-04-27
5478	272	472.90	withdrawal	2024-03-14
5479	624	146.90	withdrawal	2023-04-07
5480	911	227.80	withdrawal	2023-06-23
5481	1215	399.10	deposit	2023-04-15
5482	1422	12.60	withdrawal	2023-01-21
5483	1626	155.00	withdrawal	2024-02-01
5484	357	107.80	deposit	2023-12-24
5485	186	60.00	withdrawal	2023-07-18
5486	1054	123.10	withdrawal	2023-10-21
5487	900	84.40	withdrawal	2024-05-23
5488	724	186.00	deposit	2024-05-15
5489	1449	496.70	withdrawal	2024-04-06
5490	880	156.00	withdrawal	2023-01-09
5491	304	18.30	withdrawal	2024-04-26
5492	337	111.50	withdrawal	2023-06-12
5493	1079	467.90	withdrawal	2023-03-23
5494	743	192.10	deposit	2024-05-20
5495	1358	116.70	withdrawal	2024-05-12
5496	314	259.50	deposit	2023-09-20
5497	1055	122.70	deposit	2024-01-16
5498	121	125.00	withdrawal	2023-02-03
5499	806	358.70	deposit	2023-10-29
5500	307	397.80	withdrawal	2024-03-04
5501	1341	19.90	withdrawal	2023-10-27
5502	484	141.10	withdrawal	2023-01-10
5503	47	317.20	withdrawal	2024-05-26
5504	1097	480.60	withdrawal	2023-07-11
5505	1280	282.20	withdrawal	2023-01-11
5506	1754	369.50	deposit	2024-02-05
5507	948	78.90	withdrawal	2024-05-13
5508	1041	213.50	withdrawal	2023-10-06
5509	1526	374.10	withdrawal	2023-02-07
5510	1475	121.30	deposit	2023-12-30
5511	768	48.90	deposit	2024-04-22
5512	1047	401.30	deposit	2023-05-03
5513	261	433.90	deposit	2023-12-16
5514	1202	115.60	deposit	2023-04-08
5515	714	41.90	withdrawal	2023-06-24
5516	1583	328.60	withdrawal	2023-11-10
5517	1560	76.80	withdrawal	2023-09-19
5518	1548	30.80	deposit	2023-01-31
5519	1102	368.30	deposit	2023-07-31
5520	686	148.20	deposit	2024-01-03
5521	1290	126.00	deposit	2023-03-29
5522	673	175.60	withdrawal	2023-05-01
5523	1573	279.80	deposit	2023-03-30
5524	119	146.30	withdrawal	2023-09-22
5525	248	319.90	withdrawal	2023-04-12
5526	839	164.70	deposit	2023-04-03
5527	1683	360.40	deposit	2023-02-02
5528	1522	450.40	withdrawal	2023-10-03
5529	1172	437.50	withdrawal	2023-04-30
5530	1447	54.70	deposit	2023-01-29
5531	1316	259.00	deposit	2023-11-10
5532	1614	104.40	withdrawal	2023-06-04
5533	1269	315.30	deposit	2023-02-22
5534	921	149.80	withdrawal	2023-11-05
5535	1412	88.20	deposit	2023-06-29
5536	868	346.50	withdrawal	2023-06-25
5537	599	339.20	withdrawal	2024-05-05
5538	920	306.10	withdrawal	2024-05-18
5539	130	406.10	deposit	2024-03-16
5540	189	359.90	withdrawal	2024-01-14
5541	1507	78.90	withdrawal	2024-05-24
5542	850	76.60	deposit	2023-10-17
5543	591	347.40	withdrawal	2023-06-10
5544	518	469.80	withdrawal	2024-01-20
5545	1150	357.20	deposit	2023-02-28
5546	723	204.20	withdrawal	2023-12-25
5547	1571	438.50	deposit	2024-01-10
5548	1536	350.40	withdrawal	2023-05-30
5549	1529	166.50	deposit	2024-05-13
5550	553	311.00	withdrawal	2024-01-09
5551	1516	323.90	withdrawal	2023-04-28
5552	155	115.50	withdrawal	2024-01-26
5553	509	417.20	deposit	2024-03-29
5554	221	270.30	withdrawal	2023-09-30
5555	1194	155.90	deposit	2024-03-17
5556	1096	488.30	deposit	2023-11-22
5557	570	466.90	deposit	2024-02-08
5558	712	367.00	withdrawal	2023-11-08
5559	913	90.00	withdrawal	2024-04-05
5560	453	129.80	withdrawal	2024-03-23
5561	446	75.90	deposit	2024-04-01
5562	619	483.60	deposit	2024-04-26
5563	1702	454.30	withdrawal	2024-05-17
5564	155	403.40	withdrawal	2023-03-04
5565	300	377.50	deposit	2024-02-15
5566	1160	428.30	deposit	2023-12-06
5567	887	96.60	withdrawal	2023-06-28
5568	717	307.60	deposit	2023-02-24
5569	137	421.70	deposit	2024-05-15
5570	1540	190.40	withdrawal	2024-02-22
5571	97	376.80	deposit	2023-12-21
5572	905	36.70	deposit	2023-06-17
5573	1643	232.20	deposit	2023-10-11
5574	1202	85.00	withdrawal	2024-01-27
5575	37	459.90	deposit	2023-03-02
5576	1344	35.10	deposit	2023-08-25
5577	636	277.20	deposit	2023-06-29
5578	1437	373.90	deposit	2023-10-06
5579	605	85.30	deposit	2023-03-06
5580	1086	146.20	deposit	2023-10-24
5581	22	122.00	deposit	2024-03-02
5582	1763	350.80	deposit	2023-12-04
5583	1041	22.70	withdrawal	2024-05-24
5584	161	184.60	deposit	2023-09-26
5585	47	449.50	withdrawal	2024-04-03
5586	1599	139.20	withdrawal	2023-03-18
5587	4	68.60	withdrawal	2023-10-12
5588	1278	495.50	withdrawal	2023-05-30
5589	999	179.00	deposit	2023-02-19
5590	1256	173.90	withdrawal	2023-02-27
5591	811	6.10	deposit	2023-05-25
5592	788	300.60	deposit	2024-04-19
5593	599	241.30	withdrawal	2023-08-07
5594	1369	454.20	deposit	2023-12-13
5595	1446	237.10	deposit	2023-11-20
5596	1456	318.90	deposit	2024-03-25
5597	1336	448.90	withdrawal	2024-05-30
5598	1067	254.60	withdrawal	2023-04-10
5599	386	87.20	deposit	2023-06-18
5600	956	228.00	deposit	2023-11-26
5601	1445	250.70	withdrawal	2023-08-19
5602	754	262.90	deposit	2023-05-27
5603	1398	367.30	deposit	2023-11-13
5604	1281	373.40	deposit	2023-07-22
5605	1616	232.60	deposit	2023-04-06
5606	492	80.70	deposit	2023-08-18
5607	1613	448.30	withdrawal	2023-11-07
5608	1329	479.20	withdrawal	2023-01-05
5609	531	250.40	deposit	2024-05-09
5610	882	321.00	deposit	2023-12-29
5611	1773	154.50	deposit	2024-05-19
5612	1566	405.80	deposit	2023-07-29
5613	1277	26.20	deposit	2024-01-17
5614	1260	465.40	deposit	2023-10-31
5615	74	340.50	deposit	2023-06-18
5616	616	242.10	deposit	2023-10-25
5617	1288	407.60	withdrawal	2023-11-23
5618	1603	318.20	withdrawal	2024-01-14
5619	1754	60.20	deposit	2023-06-19
5620	1386	405.70	withdrawal	2023-03-04
5621	950	313.70	withdrawal	2023-02-15
5622	724	218.10	withdrawal	2023-05-16
5623	279	392.20	deposit	2023-12-10
5624	1255	360.30	withdrawal	2024-01-14
5625	331	358.30	deposit	2023-11-19
5626	1050	46.80	withdrawal	2023-10-26
5627	1311	418.30	withdrawal	2023-12-10
5628	51	66.40	deposit	2024-05-20
5629	1290	261.00	deposit	2024-02-19
5630	1188	33.00	deposit	2023-12-20
5631	155	231.90	withdrawal	2023-09-23
5632	673	466.70	withdrawal	2023-02-10
5633	617	259.50	withdrawal	2024-02-10
5634	1493	179.30	withdrawal	2023-02-10
5635	1224	64.10	deposit	2023-10-11
5636	606	51.00	deposit	2023-01-19
5637	382	485.00	deposit	2023-11-22
5638	681	402.80	withdrawal	2023-08-05
5639	1343	207.50	withdrawal	2024-03-10
5640	31	313.10	deposit	2023-11-21
5641	689	229.90	withdrawal	2024-01-08
5642	1349	353.00	deposit	2023-05-16
5643	869	459.20	deposit	2024-03-07
5644	778	256.30	withdrawal	2023-07-20
5645	1167	474.50	withdrawal	2023-05-29
5646	1581	384.60	withdrawal	2023-12-22
5647	619	92.00	withdrawal	2023-07-19
5648	591	215.50	deposit	2023-11-09
5649	1349	444.50	deposit	2023-03-11
5650	626	87.30	deposit	2024-04-24
5651	1154	198.70	deposit	2023-12-07
5652	645	107.20	withdrawal	2023-12-01
5653	578	496.30	deposit	2024-01-10
5654	496	289.00	withdrawal	2023-01-24
5655	1090	117.60	withdrawal	2024-02-04
5656	788	307.50	deposit	2023-11-24
5657	805	317.50	withdrawal	2023-04-20
5658	103	433.30	withdrawal	2023-05-15
5659	1762	276.00	withdrawal	2023-02-03
5660	1783	445.80	withdrawal	2024-05-25
5661	738	475.10	deposit	2023-03-04
5662	169	464.90	deposit	2023-12-23
5663	535	65.70	deposit	2023-12-01
5664	711	269.70	withdrawal	2024-01-17
5665	686	458.30	deposit	2024-01-15
5666	1389	208.10	deposit	2023-03-05
5667	280	25.20	deposit	2023-09-15
5668	1101	295.70	deposit	2023-07-22
5669	1702	338.00	deposit	2023-04-15
5670	1506	200.80	withdrawal	2023-09-26
5671	1532	39.30	withdrawal	2023-06-29
5672	676	238.50	deposit	2023-10-07
5673	1697	494.70	deposit	2024-04-05
5674	500	364.50	deposit	2023-06-22
5675	1530	469.30	deposit	2023-12-04
5676	1199	441.50	withdrawal	2023-02-22
5677	1310	442.70	deposit	2023-08-30
5678	813	115.70	withdrawal	2024-05-07
5679	1702	363.10	withdrawal	2023-07-15
5680	1165	225.70	deposit	2023-08-24
5681	1016	177.40	withdrawal	2023-05-20
5682	1392	432.70	withdrawal	2023-05-25
5683	557	431.60	withdrawal	2023-01-18
5684	1151	374.00	deposit	2024-03-29
5685	1371	376.50	deposit	2023-09-16
5686	955	12.60	withdrawal	2024-04-04
5687	912	273.30	deposit	2023-06-17
5688	170	294.00	deposit	2023-10-30
5689	461	482.30	deposit	2023-02-17
5690	70	385.80	withdrawal	2023-09-05
5691	252	329.60	withdrawal	2023-02-20
5692	443	384.00	deposit	2024-04-18
5693	270	126.80	deposit	2024-01-20
5694	837	347.70	deposit	2023-04-16
5695	491	150.80	deposit	2023-03-14
5696	953	333.90	withdrawal	2023-03-05
5697	309	310.10	deposit	2023-10-07
5698	466	92.30	deposit	2023-08-04
5699	1303	404.00	withdrawal	2023-04-05
5700	1521	315.70	withdrawal	2023-06-20
5701	1651	52.00	deposit	2023-05-05
5702	479	31.50	withdrawal	2023-03-27
5703	1162	24.80	withdrawal	2024-05-14
5704	989	455.10	withdrawal	2024-04-09
5705	808	49.60	deposit	2023-12-06
5706	1604	13.20	withdrawal	2023-05-03
5707	1782	303.90	withdrawal	2023-08-06
5708	754	319.40	withdrawal	2023-05-12
5709	1186	494.60	withdrawal	2023-07-02
5710	51	81.60	withdrawal	2024-04-15
5711	1069	105.00	deposit	2023-07-03
5712	844	429.10	withdrawal	2023-11-24
5713	572	212.90	deposit	2024-05-15
5714	1527	415.40	withdrawal	2023-03-24
5715	1453	26.30	deposit	2023-12-24
5716	119	16.40	deposit	2023-03-05
5717	359	70.10	withdrawal	2023-09-23
5718	1455	381.10	deposit	2024-03-18
5719	1462	65.00	deposit	2023-06-24
5720	1196	38.40	deposit	2023-04-27
5721	1773	457.00	withdrawal	2024-05-08
5722	891	456.80	deposit	2024-01-13
5723	1582	66.30	withdrawal	2024-04-17
5724	534	343.50	deposit	2023-02-11
5725	112	39.00	withdrawal	2023-05-10
5726	531	298.10	withdrawal	2023-09-22
5727	839	169.20	deposit	2023-10-01
5728	769	74.80	withdrawal	2023-12-02
5729	1381	428.00	deposit	2024-03-27
5730	1381	358.30	withdrawal	2023-10-18
5731	120	157.50	deposit	2023-07-15
5732	370	382.40	deposit	2023-09-06
5733	814	39.30	withdrawal	2023-10-01
5734	682	437.60	withdrawal	2023-02-04
5735	742	498.90	deposit	2023-01-19
5736	53	271.60	deposit	2023-10-20
5737	976	337.90	deposit	2023-08-18
5738	1175	388.40	withdrawal	2024-05-20
5739	1560	228.40	deposit	2024-02-29
5740	848	197.50	deposit	2024-04-24
5741	1067	147.00	withdrawal	2023-07-24
5742	1126	456.70	withdrawal	2023-11-16
5743	724	490.90	withdrawal	2023-05-10
5744	644	125.90	deposit	2023-03-07
5745	1356	366.80	deposit	2023-10-22
5746	311	498.70	deposit	2023-05-03
5747	1521	83.60	withdrawal	2023-07-18
5748	1792	265.50	withdrawal	2023-12-03
5749	831	244.50	withdrawal	2024-05-22
5750	554	404.00	withdrawal	2023-05-31
5751	730	184.40	deposit	2023-04-08
5752	1059	320.00	withdrawal	2024-03-10
5753	130	372.30	withdrawal	2023-06-15
5754	1398	424.10	withdrawal	2023-09-24
5755	124	103.40	deposit	2024-03-09
5756	229	456.10	withdrawal	2023-11-05
5757	974	234.90	deposit	2023-03-05
5758	1085	64.10	deposit	2023-05-25
5759	1045	344.60	withdrawal	2023-03-05
5760	1316	215.10	deposit	2023-06-27
5761	1121	236.40	deposit	2023-05-10
5762	888	383.30	withdrawal	2023-01-06
5763	383	484.20	deposit	2023-02-02
5764	216	360.30	deposit	2024-05-03
5765	583	236.70	withdrawal	2023-04-13
5766	654	10.60	withdrawal	2023-06-30
5767	1447	129.40	deposit	2023-03-11
5768	802	183.20	deposit	2024-05-08
5769	100	94.20	deposit	2023-06-08
5770	443	106.80	deposit	2023-05-08
5771	1233	458.90	withdrawal	2023-10-02
5772	278	304.80	deposit	2023-08-29
5773	328	191.20	withdrawal	2024-04-16
5774	328	206.10	withdrawal	2024-03-17
5775	128	36.10	deposit	2023-02-03
5776	1214	192.10	withdrawal	2023-03-11
5777	1324	482.30	withdrawal	2023-06-07
5778	389	165.10	deposit	2024-03-16
5779	1574	148.00	deposit	2024-01-05
5780	504	115.80	deposit	2023-02-18
5781	772	343.20	withdrawal	2023-08-12
5782	30	418.70	deposit	2024-05-16
5783	1103	375.50	deposit	2023-10-04
5784	95	476.70	deposit	2023-05-10
5785	830	342.40	withdrawal	2023-07-06
5786	1531	498.20	deposit	2023-08-01
5787	965	336.80	deposit	2023-09-30
5788	102	313.40	deposit	2023-09-29
5789	563	487.00	withdrawal	2023-12-13
5790	135	316.50	withdrawal	2023-02-14
5791	1146	410.30	deposit	2023-08-27
5792	1640	46.40	withdrawal	2024-03-01
5793	1458	143.40	withdrawal	2023-11-01
5794	5	240.20	deposit	2023-07-18
5795	262	143.00	withdrawal	2024-02-22
5796	1354	28.30	withdrawal	2024-01-17
5797	576	229.30	withdrawal	2023-07-28
5798	120	62.80	withdrawal	2023-10-22
5799	916	26.60	withdrawal	2023-04-12
5800	1769	283.80	withdrawal	2023-06-20
5801	897	416.50	withdrawal	2023-12-30
5802	473	356.70	deposit	2023-10-10
5803	1154	244.80	deposit	2023-10-21
5804	1711	306.00	withdrawal	2023-07-26
5805	848	6.00	withdrawal	2024-03-15
5806	1672	201.50	withdrawal	2023-12-18
5807	893	261.90	withdrawal	2024-01-12
5808	680	75.80	withdrawal	2023-02-17
5809	1468	500.00	deposit	2023-01-20
5810	1217	376.50	deposit	2023-03-10
5811	558	26.60	withdrawal	2024-01-21
5812	514	162.40	deposit	2023-07-13
5813	1650	98.90	deposit	2024-02-13
5814	1637	118.50	withdrawal	2024-03-02
5815	32	46.80	withdrawal	2023-09-20
5816	213	210.20	deposit	2023-02-13
5817	977	351.80	withdrawal	2023-09-17
5818	172	274.30	withdrawal	2024-05-20
5819	1766	296.70	deposit	2023-06-17
5820	1359	465.00	deposit	2024-05-15
5821	1702	446.90	withdrawal	2023-08-25
5822	1576	181.10	withdrawal	2023-05-05
5823	864	232.50	withdrawal	2024-01-19
5824	408	45.30	withdrawal	2023-05-30
5825	733	338.70	deposit	2024-03-27
5826	743	457.00	withdrawal	2024-04-15
5827	1337	458.70	withdrawal	2023-08-27
5828	935	393.00	deposit	2023-11-14
5829	1046	88.00	deposit	2023-02-23
5830	1205	50.40	deposit	2024-03-22
5831	1314	206.00	withdrawal	2024-01-11
5832	759	99.60	withdrawal	2023-11-01
5833	1261	367.60	deposit	2024-01-20
5834	424	189.40	withdrawal	2023-08-23
5835	294	466.60	withdrawal	2023-07-10
5836	86	430.00	deposit	2023-02-03
5837	209	260.50	deposit	2023-01-04
5838	192	260.60	withdrawal	2024-04-23
5839	136	313.70	withdrawal	2023-11-02
5840	697	180.40	withdrawal	2023-06-21
5841	562	116.90	withdrawal	2023-02-10
5842	1429	101.00	withdrawal	2023-08-13
5843	1272	236.30	withdrawal	2023-02-12
5844	671	410.70	deposit	2023-09-01
5845	1524	142.90	deposit	2023-06-29
5846	852	353.10	withdrawal	2024-01-12
5847	481	5.50	deposit	2023-03-17
5848	324	315.20	withdrawal	2024-05-05
5849	1756	284.30	withdrawal	2023-06-25
5850	1445	402.30	withdrawal	2023-10-11
5851	1015	228.90	withdrawal	2023-10-14
5852	1195	121.90	deposit	2023-10-06
5853	1300	7.80	deposit	2023-10-15
5854	195	86.20	deposit	2023-02-27
5855	43	376.10	deposit	2024-02-13
5856	1194	361.50	deposit	2023-11-15
5857	1544	67.70	deposit	2023-10-15
5858	1532	298.40	withdrawal	2023-03-30
5859	499	7.80	withdrawal	2023-07-29
5860	591	63.60	withdrawal	2023-09-28
5861	1141	386.50	deposit	2023-05-19
5862	62	412.60	withdrawal	2023-08-28
5863	770	295.20	deposit	2023-05-24
5864	645	407.60	deposit	2023-03-17
5865	21	265.20	deposit	2023-02-08
5866	303	454.50	withdrawal	2023-01-01
5867	637	149.10	deposit	2023-03-16
5868	528	150.30	withdrawal	2024-01-09
5869	832	228.10	deposit	2023-01-16
5870	245	212.70	withdrawal	2024-03-21
5871	1762	346.60	withdrawal	2023-06-30
5872	735	13.20	withdrawal	2023-03-09
5873	459	317.70	deposit	2023-08-30
5874	252	173.10	withdrawal	2023-12-17
5875	445	466.70	deposit	2024-05-30
5876	1040	476.50	withdrawal	2023-08-06
5877	571	370.20	withdrawal	2024-01-23
5878	1433	78.70	deposit	2023-09-01
5879	1651	13.40	deposit	2023-04-20
5880	1442	241.20	withdrawal	2023-12-16
5881	272	56.30	deposit	2023-05-10
5882	624	113.80	deposit	2024-05-19
5883	1699	311.90	deposit	2023-04-17
5884	408	51.00	deposit	2023-10-31
5885	72	472.50	withdrawal	2024-04-13
5886	1682	457.40	deposit	2023-07-08
5887	1365	75.80	withdrawal	2023-02-10
5888	1677	366.50	deposit	2023-01-05
5889	1535	235.30	withdrawal	2023-07-07
5890	1752	332.10	withdrawal	2023-10-10
5891	1524	297.50	withdrawal	2024-04-09
5892	337	390.00	withdrawal	2024-05-11
5893	1003	91.70	deposit	2023-08-12
5894	745	409.50	deposit	2023-03-04
5895	1551	433.20	deposit	2023-10-06
5896	309	386.70	deposit	2023-05-06
5897	896	354.70	deposit	2024-03-12
5898	876	371.60	deposit	2024-04-27
5899	520	43.80	deposit	2023-03-31
5900	491	88.70	deposit	2023-01-31
5901	681	238.80	deposit	2023-11-16
5902	1	16.10	withdrawal	2024-05-15
5903	1628	334.50	deposit	2024-05-29
5904	406	76.30	withdrawal	2024-01-27
5905	1297	257.90	deposit	2023-04-07
5906	81	96.10	deposit	2023-07-19
5907	1376	234.40	deposit	2023-07-25
5908	300	128.70	deposit	2024-05-23
5909	453	398.80	withdrawal	2023-09-20
5910	1493	284.90	deposit	2023-09-26
5911	769	241.70	withdrawal	2023-02-16
5912	1116	374.30	withdrawal	2023-01-16
5913	688	18.90	deposit	2023-07-17
5914	1765	154.70	withdrawal	2023-07-08
5915	1778	78.00	deposit	2023-08-08
5916	221	237.80	withdrawal	2023-06-24
5917	1548	337.30	withdrawal	2023-11-29
5918	1222	144.80	deposit	2024-03-21
5919	913	470.20	deposit	2024-04-25
5920	995	229.60	withdrawal	2023-01-22
5921	1223	315.00	withdrawal	2023-01-24
5922	747	36.30	withdrawal	2024-02-22
5923	466	473.70	withdrawal	2023-05-25
5924	1315	177.40	withdrawal	2023-04-20
5925	1548	21.30	withdrawal	2023-11-12
5926	1599	368.10	withdrawal	2023-02-04
5927	1042	227.60	withdrawal	2024-04-01
5928	1551	6.30	withdrawal	2024-03-29
5929	679	33.10	withdrawal	2024-03-06
5930	306	65.50	withdrawal	2024-01-18
5931	1363	226.70	withdrawal	2023-10-07
5932	336	241.90	withdrawal	2023-12-27
5933	1747	476.00	deposit	2023-12-07
5934	1188	235.30	withdrawal	2023-10-04
5935	248	216.80	deposit	2023-10-06
5936	1204	86.30	deposit	2023-03-21
5937	982	18.70	deposit	2023-10-20
5938	1556	329.40	deposit	2023-12-02
5939	9	263.70	withdrawal	2023-12-23
5940	44	210.70	withdrawal	2023-02-16
5941	1594	407.60	deposit	2023-08-13
5942	15	459.30	withdrawal	2024-04-17
5943	493	479.20	deposit	2023-10-10
5944	640	275.90	deposit	2023-05-14
5945	1558	25.50	deposit	2023-09-23
5946	801	133.90	withdrawal	2023-05-09
5947	1681	186.80	deposit	2023-02-13
5948	1284	450.70	withdrawal	2023-01-14
5949	558	477.60	withdrawal	2023-05-11
5950	1776	206.60	withdrawal	2023-07-24
5951	1509	267.00	deposit	2023-02-20
5952	1126	291.60	deposit	2023-04-17
5953	1620	469.10	deposit	2024-04-20
5954	1505	14.00	withdrawal	2023-06-08
5955	851	103.90	deposit	2023-06-21
5956	243	142.70	deposit	2024-02-20
5957	992	194.50	withdrawal	2023-09-15
5958	622	89.10	withdrawal	2023-06-14
5959	1494	355.90	withdrawal	2023-02-11
5960	215	122.50	withdrawal	2024-05-30
5961	639	286.90	withdrawal	2024-03-05
5962	313	277.10	withdrawal	2023-02-13
5963	1028	79.30	withdrawal	2024-04-22
5964	1661	453.10	deposit	2023-11-24
5965	840	35.90	withdrawal	2024-02-02
5966	1109	320.30	withdrawal	2023-02-05
5967	705	238.80	deposit	2024-03-26
5968	1077	67.70	withdrawal	2023-07-11
5969	353	323.40	withdrawal	2024-01-15
5970	1602	111.60	deposit	2023-07-06
5971	1207	161.70	deposit	2023-03-16
5972	694	355.40	withdrawal	2023-02-16
5973	1350	477.80	deposit	2023-01-20
5974	521	375.60	withdrawal	2024-05-24
5975	1631	462.70	withdrawal	2023-10-03
5976	1375	237.60	withdrawal	2023-10-01
5977	1561	230.90	withdrawal	2023-01-21
5978	488	473.20	withdrawal	2023-12-07
5979	1610	299.50	withdrawal	2023-11-02
5980	81	74.70	deposit	2023-06-09
5981	345	218.00	deposit	2023-05-09
5982	1727	36.70	withdrawal	2023-06-30
5983	291	213.30	deposit	2024-03-25
5984	1738	370.30	deposit	2024-05-04
5985	766	437.20	deposit	2023-04-04
5986	924	224.90	withdrawal	2023-03-23
5987	865	370.60	deposit	2023-12-02
5988	94	489.50	withdrawal	2023-12-24
5989	57	308.20	deposit	2023-05-12
5990	1370	302.00	withdrawal	2023-05-27
5991	452	485.30	deposit	2023-03-20
5992	1150	29.30	deposit	2024-05-01
5993	115	50.10	withdrawal	2023-05-20
5994	1473	34.00	deposit	2024-02-05
5995	1618	251.50	deposit	2023-05-14
5996	916	40.50	withdrawal	2023-04-09
5997	618	422.90	deposit	2023-01-09
5998	859	118.50	withdrawal	2023-04-19
5999	941	86.50	withdrawal	2023-06-21
6000	1722	446.70	deposit	2023-03-20
6001	1711	125.50	deposit	2023-04-28
6002	1528	302.20	withdrawal	2024-04-13
6003	894	65.10	deposit	2023-08-10
6004	1663	135.60	withdrawal	2023-10-13
6005	1148	170.10	withdrawal	2023-03-29
6006	954	499.70	deposit	2023-03-08
6007	269	155.40	withdrawal	2024-03-08
6008	871	500.20	withdrawal	2023-09-12
6009	1167	141.30	deposit	2023-12-03
6010	318	378.80	withdrawal	2023-07-24
6011	358	364.80	withdrawal	2023-04-02
6012	1007	177.10	withdrawal	2024-05-13
6013	1057	36.90	deposit	2023-02-23
6014	728	323.80	withdrawal	2023-05-01
6015	1345	456.20	deposit	2024-01-26
6016	700	370.80	withdrawal	2023-01-20
6017	1147	70.80	withdrawal	2023-04-09
6018	1622	474.20	withdrawal	2023-05-21
6019	1461	25.80	withdrawal	2023-03-12
6020	91	160.60	deposit	2023-01-11
6021	1774	198.40	deposit	2023-03-15
6022	637	467.50	deposit	2023-06-09
6023	578	233.80	withdrawal	2023-09-01
6024	1428	486.60	deposit	2023-01-22
6025	743	493.20	deposit	2024-04-29
6026	395	69.70	withdrawal	2024-01-24
6027	214	421.30	deposit	2024-03-20
6028	1001	488.40	deposit	2023-03-29
6029	324	468.10	deposit	2023-02-09
6030	26	105.00	deposit	2024-01-15
6031	962	148.50	withdrawal	2023-01-24
6032	802	447.20	withdrawal	2024-04-12
6033	476	58.20	withdrawal	2023-03-15
6034	1600	23.00	withdrawal	2024-03-25
6035	1038	261.50	withdrawal	2024-01-11
6036	1316	365.10	withdrawal	2024-04-24
6037	1357	88.20	deposit	2024-03-25
6038	386	249.20	withdrawal	2023-09-03
6039	1038	393.30	deposit	2023-11-12
6040	1569	315.60	withdrawal	2024-03-24
6041	389	448.60	deposit	2023-07-24
6042	405	500.10	deposit	2023-10-20
6043	1428	476.30	withdrawal	2023-03-13
6044	84	310.80	deposit	2023-10-20
6045	462	62.50	deposit	2023-05-22
6046	1047	209.00	withdrawal	2023-12-07
6047	1500	360.70	withdrawal	2024-02-08
6048	934	125.50	withdrawal	2024-04-30
6049	864	450.30	withdrawal	2023-11-01
6050	1793	404.30	withdrawal	2023-12-04
6051	1377	365.70	withdrawal	2024-03-09
6052	1240	188.30	withdrawal	2023-12-24
6053	1443	420.40	withdrawal	2023-01-28
6054	1006	458.80	withdrawal	2023-07-29
6055	257	383.80	deposit	2023-01-29
6056	978	297.60	deposit	2023-12-11
6057	16	320.80	withdrawal	2023-06-16
6058	1039	488.10	deposit	2023-12-12
6059	373	226.10	deposit	2023-02-10
6060	997	72.80	withdrawal	2023-05-08
6061	282	362.70	withdrawal	2024-02-14
6062	353	30.70	withdrawal	2023-07-25
6063	1772	246.90	withdrawal	2024-05-06
6064	1235	377.90	withdrawal	2023-12-25
6065	536	77.10	deposit	2023-12-08
6066	38	420.10	deposit	2023-08-15
6067	1476	377.20	withdrawal	2024-03-17
6068	856	254.60	deposit	2023-12-17
6069	799	33.40	deposit	2024-05-19
6070	303	219.50	withdrawal	2024-01-31
6071	854	10.50	deposit	2024-05-29
6072	1169	457.80	deposit	2023-10-07
6073	1766	367.00	deposit	2024-05-30
6074	194	292.90	withdrawal	2024-03-26
6075	516	70.20	withdrawal	2023-01-07
6076	1392	344.80	withdrawal	2023-03-05
6077	1222	429.70	withdrawal	2023-04-30
6078	880	124.90	deposit	2023-09-12
6079	1544	25.30	deposit	2023-09-05
6080	1584	131.90	deposit	2023-08-28
6081	1391	367.90	deposit	2024-01-15
6082	1569	319.60	deposit	2024-02-22
6083	1587	122.00	withdrawal	2024-02-18
6084	1795	282.30	withdrawal	2023-07-05
6085	998	344.40	deposit	2024-01-25
6086	1576	379.90	deposit	2023-01-28
6087	1620	476.90	deposit	2023-01-07
6088	1093	94.20	deposit	2024-01-03
6089	327	456.10	deposit	2023-02-23
6090	1350	78.30	withdrawal	2024-04-19
6091	676	273.90	deposit	2023-02-16
6092	1102	37.70	withdrawal	2024-03-01
6093	1235	439.50	deposit	2023-09-10
6094	1719	317.40	deposit	2024-01-15
6095	1667	208.70	withdrawal	2023-04-01
6096	533	318.40	withdrawal	2023-12-29
6097	369	355.50	deposit	2023-08-13
6098	1459	341.10	withdrawal	2023-04-13
6099	561	93.70	deposit	2023-03-18
6100	94	440.10	deposit	2023-11-05
6101	1043	21.90	deposit	2023-05-21
6102	427	152.60	withdrawal	2023-04-14
6103	574	467.40	deposit	2023-06-22
6104	135	238.90	withdrawal	2023-09-11
6105	1465	176.60	withdrawal	2023-02-20
6106	731	449.30	withdrawal	2024-04-16
6107	572	310.40	withdrawal	2023-11-04
6108	939	384.30	withdrawal	2023-10-20
6109	955	51.50	deposit	2023-09-17
6110	1647	182.60	withdrawal	2023-05-17
6111	1611	452.90	deposit	2024-01-29
6112	1104	171.20	withdrawal	2023-10-06
6113	201	18.40	withdrawal	2024-04-09
6114	1266	267.20	withdrawal	2023-08-15
6115	1306	199.40	deposit	2023-12-11
6116	534	49.50	withdrawal	2023-11-27
6117	939	232.50	withdrawal	2023-05-10
6118	475	156.00	deposit	2024-02-08
6119	1334	190.90	withdrawal	2023-04-02
6120	1702	64.70	withdrawal	2024-01-03
6121	833	123.80	deposit	2024-03-15
6122	845	412.00	withdrawal	2023-08-29
6123	680	35.80	deposit	2024-01-14
6124	708	246.30	withdrawal	2023-03-21
6125	1597	481.50	deposit	2023-08-15
6126	318	51.30	deposit	2024-03-14
6127	1647	12.70	deposit	2024-03-17
6128	850	188.90	withdrawal	2024-03-30
6129	297	86.40	deposit	2024-05-31
6130	1214	476.70	withdrawal	2023-04-26
6131	1677	491.00	deposit	2023-11-21
6132	1169	93.50	deposit	2023-06-17
6133	946	277.70	withdrawal	2024-04-17
6134	1254	321.60	withdrawal	2023-10-20
6135	390	162.30	deposit	2023-06-12
6136	1533	402.20	deposit	2023-09-06
6137	1515	267.50	withdrawal	2023-07-14
6138	1002	294.20	withdrawal	2024-01-26
6139	1334	348.50	deposit	2023-04-25
6140	382	114.40	deposit	2023-08-10
6141	628	405.80	deposit	2024-01-21
6142	701	280.50	withdrawal	2023-11-21
6143	1776	105.90	deposit	2024-05-06
6144	1472	372.10	deposit	2023-12-20
6145	1490	366.10	withdrawal	2024-02-25
6146	396	339.80	deposit	2024-03-01
6147	1223	20.00	withdrawal	2024-05-24
6148	342	16.30	withdrawal	2023-12-17
6149	229	18.50	deposit	2023-03-03
6150	96	403.90	deposit	2023-01-20
6151	481	299.80	deposit	2023-07-12
6152	536	44.50	deposit	2023-01-15
6153	442	383.30	deposit	2023-01-14
6154	1107	134.20	withdrawal	2023-01-16
6155	1469	383.00	deposit	2024-02-06
6156	1764	215.60	deposit	2023-06-11
6157	47	247.60	deposit	2023-03-10
6158	736	18.70	deposit	2024-02-29
6159	1501	429.20	withdrawal	2023-11-04
6160	371	275.00	withdrawal	2024-03-15
6161	1343	233.20	deposit	2023-05-13
6162	300	283.80	deposit	2023-12-20
6163	278	390.20	deposit	2023-01-14
6164	1002	292.20	deposit	2024-04-02
6165	1735	150.10	deposit	2024-05-25
6166	1279	446.30	withdrawal	2023-05-19
6167	824	121.20	withdrawal	2024-02-22
6168	225	224.40	withdrawal	2024-01-16
6169	377	480.20	deposit	2023-04-16
6170	1412	88.30	withdrawal	2023-01-18
6171	1040	143.20	deposit	2024-01-24
6172	418	465.20	withdrawal	2024-02-23
6173	452	376.70	withdrawal	2024-05-15
6174	680	121.80	deposit	2023-11-27
6175	271	314.60	deposit	2024-01-26
6176	1186	474.70	withdrawal	2024-01-16
6177	1604	389.10	deposit	2023-05-28
6178	163	103.20	deposit	2024-03-24
6179	279	70.50	withdrawal	2023-03-11
6180	1062	206.00	deposit	2024-05-22
6181	1563	138.60	deposit	2023-06-10
6182	1190	484.00	deposit	2023-03-11
6183	631	463.90	withdrawal	2024-04-09
6184	1459	54.80	deposit	2024-01-13
6185	1023	36.40	withdrawal	2023-09-27
6186	615	495.90	withdrawal	2024-05-09
6187	905	263.00	withdrawal	2023-08-06
6188	84	412.30	withdrawal	2023-09-08
6189	1033	296.70	deposit	2023-01-21
6190	1218	49.50	withdrawal	2024-04-03
6191	537	122.00	deposit	2023-08-22
6192	173	205.80	deposit	2024-05-26
6193	469	497.00	deposit	2023-04-11
6194	485	391.60	withdrawal	2024-03-14
6195	1360	410.00	deposit	2023-01-15
6196	79	125.00	withdrawal	2024-02-01
6197	155	344.00	withdrawal	2024-04-08
6198	15	309.30	withdrawal	2024-03-12
6199	1012	455.50	withdrawal	2024-02-07
6200	54	39.50	withdrawal	2024-05-22
6201	1673	478.90	deposit	2024-02-13
6202	100	79.00	deposit	2023-05-16
6203	1026	157.40	deposit	2023-07-02
6204	554	270.00	withdrawal	2023-11-08
6205	387	488.20	withdrawal	2023-06-20
6206	150	360.10	withdrawal	2024-04-11
6207	545	117.90	deposit	2023-04-30
6208	702	223.90	deposit	2024-05-23
6209	1655	115.60	deposit	2023-02-19
6210	1507	85.30	withdrawal	2023-05-05
6211	1277	152.30	deposit	2024-03-21
6212	1395	31.60	deposit	2024-03-30
6213	431	195.10	deposit	2024-03-22
6214	1739	190.20	deposit	2023-05-27
6215	1314	185.40	withdrawal	2023-01-27
6216	1753	22.30	withdrawal	2023-11-05
6217	843	409.80	deposit	2023-06-24
6218	1246	31.10	withdrawal	2023-02-24
6219	637	260.00	withdrawal	2023-08-12
6220	546	345.60	withdrawal	2023-06-09
6221	1701	374.60	withdrawal	2023-01-25
6222	539	80.20	deposit	2023-09-19
6223	304	94.70	deposit	2024-01-29
6224	324	172.60	withdrawal	2023-06-26
6225	393	456.90	withdrawal	2023-12-24
6226	1112	431.40	deposit	2024-01-30
6227	277	369.70	withdrawal	2024-04-07
6228	794	493.20	withdrawal	2023-11-19
6229	1320	5.80	deposit	2023-06-24
6230	1661	391.70	deposit	2023-02-17
6231	1354	484.40	deposit	2023-06-28
6232	1581	376.50	withdrawal	2023-08-13
6233	879	195.20	deposit	2023-09-18
6234	385	107.10	withdrawal	2024-04-11
6235	156	93.00	withdrawal	2024-05-23
6236	1476	319.80	deposit	2023-12-23
6237	427	489.10	deposit	2023-02-12
6238	73	222.10	deposit	2024-03-22
6239	1399	460.30	deposit	2023-05-11
6240	1657	70.90	withdrawal	2023-08-10
6241	74	254.00	deposit	2023-01-05
6242	874	490.60	deposit	2023-06-08
6243	212	114.70	deposit	2023-07-25
6244	728	96.30	deposit	2023-09-11
6245	1267	340.00	deposit	2024-04-30
6246	1002	413.60	withdrawal	2023-06-05
6247	1617	335.50	deposit	2023-06-28
6248	1538	140.00	deposit	2023-02-13
6249	147	59.30	withdrawal	2024-02-12
6250	49	484.90	deposit	2023-03-14
6251	1548	8.20	deposit	2023-07-24
6252	13	47.10	deposit	2023-10-22
6253	965	61.40	withdrawal	2023-09-01
6254	1613	59.00	withdrawal	2023-12-03
6255	1046	37.60	withdrawal	2023-02-06
6256	985	365.60	deposit	2024-05-17
6257	1280	470.20	deposit	2023-08-22
6258	369	463.50	deposit	2023-02-08
6259	1662	336.70	deposit	2023-05-19
6260	1746	323.70	deposit	2023-11-07
6261	1085	380.70	deposit	2023-12-07
6262	644	19.30	deposit	2023-04-26
6263	1213	439.20	withdrawal	2024-03-15
6264	375	467.50	deposit	2023-07-05
6265	984	22.00	deposit	2023-12-05
6266	189	33.70	deposit	2024-03-21
6267	1551	107.10	withdrawal	2023-12-21
6268	1055	372.10	deposit	2024-02-03
6269	1406	454.70	withdrawal	2023-11-11
6270	1151	203.50	withdrawal	2024-01-23
6271	1736	309.20	deposit	2023-09-24
6272	1355	457.80	withdrawal	2024-05-09
6273	1093	167.60	deposit	2023-06-02
6274	524	175.20	deposit	2024-04-30
6275	1157	262.40	deposit	2024-02-12
6276	1442	466.60	withdrawal	2024-02-11
6277	492	89.70	deposit	2023-08-16
6278	758	335.80	deposit	2024-05-09
6279	512	48.00	withdrawal	2023-09-30
6280	1132	477.30	withdrawal	2023-03-18
6281	701	287.50	withdrawal	2023-10-25
6282	1329	112.90	withdrawal	2023-07-11
6283	142	57.70	deposit	2023-11-25
6284	1751	479.30	withdrawal	2023-08-21
6285	1296	210.20	withdrawal	2023-02-02
6286	1110	194.30	deposit	2023-04-12
6287	980	396.80	withdrawal	2023-12-14
6288	1171	263.50	deposit	2023-12-23
6289	1771	252.10	withdrawal	2023-05-18
6290	757	485.70	deposit	2023-06-23
6291	790	272.10	withdrawal	2023-10-17
6292	391	282.30	withdrawal	2023-09-04
6293	161	304.20	deposit	2023-03-25
6294	1146	91.70	withdrawal	2023-06-18
6295	1113	456.00	deposit	2023-07-07
6296	1466	150.90	withdrawal	2024-03-02
6297	618	407.30	withdrawal	2023-02-28
6298	640	439.90	withdrawal	2024-05-08
6299	51	139.00	deposit	2023-07-01
6300	1326	265.80	deposit	2023-10-11
6301	1758	145.30	deposit	2023-01-14
6302	1059	244.00	deposit	2023-11-15
6303	154	221.20	withdrawal	2023-01-23
6304	882	243.70	deposit	2023-09-26
6305	1229	448.40	deposit	2023-03-20
6306	728	180.40	deposit	2024-05-21
6307	1632	356.80	deposit	2023-04-21
6308	542	121.80	withdrawal	2023-08-08
6309	1406	395.10	deposit	2023-04-16
6310	1551	192.30	withdrawal	2023-10-24
6311	1656	499.40	withdrawal	2023-09-30
6312	1491	373.40	withdrawal	2023-04-05
6313	265	393.20	withdrawal	2023-05-07
6314	1794	183.90	deposit	2024-05-31
6315	941	324.10	deposit	2023-04-23
6316	100	322.10	withdrawal	2023-09-15
6317	1669	35.60	withdrawal	2023-07-27
6318	1228	64.30	withdrawal	2023-01-06
6319	1054	412.30	deposit	2023-01-13
6320	516	200.60	deposit	2023-04-13
6321	860	143.70	withdrawal	2024-02-10
6322	101	435.30	deposit	2024-01-22
6323	813	451.70	withdrawal	2023-08-11
6324	962	478.70	withdrawal	2023-09-14
6325	667	285.80	deposit	2023-10-31
6326	1364	64.70	withdrawal	2023-10-02
6327	1343	277.30	withdrawal	2024-02-27
6328	1573	73.80	withdrawal	2023-06-19
6329	1446	355.80	withdrawal	2023-10-15
6330	1228	112.50	withdrawal	2024-04-23
6331	3	243.10	deposit	2023-11-21
6332	228	149.30	deposit	2023-07-11
6333	1151	91.20	deposit	2023-03-29
6334	103	73.10	deposit	2023-05-26
6335	844	475.00	deposit	2024-01-18
6336	452	178.20	withdrawal	2023-08-31
6337	1493	153.50	deposit	2023-11-26
6338	249	241.20	deposit	2023-10-02
6339	493	341.90	deposit	2023-07-08
6340	762	27.60	deposit	2023-10-06
6341	1067	366.10	deposit	2023-04-13
6342	1001	159.20	deposit	2023-02-01
6343	1326	202.50	withdrawal	2023-11-24
6344	1464	219.10	withdrawal	2024-01-11
6345	301	325.40	deposit	2023-08-10
6346	1562	332.40	deposit	2023-02-10
6347	1417	249.80	deposit	2023-11-19
6348	821	297.30	withdrawal	2023-05-27
6349	1632	381.30	withdrawal	2023-12-18
6350	400	312.90	deposit	2024-03-10
6351	1169	255.30	withdrawal	2023-11-13
6352	1292	177.80	withdrawal	2023-06-08
6353	186	269.70	withdrawal	2023-07-06
6354	1037	76.80	deposit	2023-08-01
6355	1077	363.20	withdrawal	2023-04-10
6356	236	399.90	deposit	2024-01-24
6357	1110	132.50	deposit	2023-02-22
6358	1140	435.10	deposit	2023-12-25
6359	792	32.20	deposit	2023-06-11
6360	1369	385.20	deposit	2023-02-21
6361	1752	151.80	deposit	2023-11-30
6362	546	238.20	deposit	2023-05-30
6363	1114	365.70	withdrawal	2023-03-31
6364	1226	371.20	deposit	2024-05-30
6365	993	348.80	withdrawal	2024-05-14
6366	1553	265.00	withdrawal	2023-10-11
6367	866	425.20	deposit	2023-12-11
6368	1788	367.70	withdrawal	2023-01-20
6369	1225	338.70	deposit	2023-01-11
6370	1697	314.60	withdrawal	2024-03-03
6371	91	137.00	deposit	2023-01-08
6372	580	115.70	withdrawal	2023-07-13
6373	673	409.90	withdrawal	2024-01-03
6374	248	38.00	deposit	2023-06-17
6375	97	282.00	deposit	2023-08-26
6376	439	302.20	withdrawal	2023-07-08
6377	1714	65.20	deposit	2023-06-14
6378	851	339.90	deposit	2023-03-01
6379	817	364.50	deposit	2024-05-27
6380	773	341.00	withdrawal	2024-02-18
6381	1150	472.50	deposit	2023-08-25
6382	1043	75.40	withdrawal	2023-05-06
6383	1213	12.50	withdrawal	2023-09-11
6384	161	254.50	withdrawal	2023-08-10
6385	163	137.00	withdrawal	2023-04-17
6386	698	267.60	withdrawal	2024-05-11
6387	1264	465.80	deposit	2023-06-09
6388	1044	97.40	withdrawal	2023-07-21
6389	315	377.20	deposit	2023-08-01
6390	1643	168.00	withdrawal	2024-03-23
6391	886	91.20	withdrawal	2023-03-15
6392	1259	67.00	deposit	2023-02-20
6393	146	249.20	withdrawal	2023-08-13
6394	492	462.10	deposit	2023-12-13
6395	828	251.80	withdrawal	2024-03-03
6396	50	29.50	withdrawal	2024-05-22
6397	1332	470.20	deposit	2023-01-07
6398	741	408.70	withdrawal	2023-10-04
6399	128	53.80	withdrawal	2023-04-22
6400	763	56.10	withdrawal	2024-01-08
6401	705	145.90	deposit	2023-03-01
6402	1705	369.80	withdrawal	2024-05-15
6403	633	72.20	withdrawal	2023-02-02
6404	1033	281.30	deposit	2023-05-18
6405	1045	160.50	deposit	2023-01-26
6406	1249	414.60	withdrawal	2023-10-15
6407	113	30.50	deposit	2023-01-15
6408	449	19.20	deposit	2023-11-21
6409	1531	311.20	deposit	2023-10-30
6410	1142	366.60	deposit	2023-07-15
6411	30	136.70	deposit	2024-04-30
6412	227	265.60	deposit	2023-11-24
6413	1354	482.80	deposit	2023-05-18
6414	581	41.00	withdrawal	2023-02-18
6415	1719	209.70	withdrawal	2023-09-03
6416	1583	269.30	withdrawal	2024-05-16
6417	983	19.30	withdrawal	2023-03-01
6418	1702	231.70	withdrawal	2023-09-11
6419	1535	68.30	deposit	2023-10-11
6420	386	386.30	withdrawal	2023-11-23
6421	625	464.80	withdrawal	2024-03-24
6422	1337	405.00	withdrawal	2023-05-07
6423	1258	133.20	deposit	2023-10-24
6424	138	374.00	deposit	2023-03-26
6425	120	95.00	withdrawal	2023-06-16
6426	1454	18.70	deposit	2023-07-14
6427	1238	131.30	deposit	2023-09-13
6428	373	492.30	withdrawal	2024-03-25
6429	1281	118.00	deposit	2023-09-12
6430	770	496.70	withdrawal	2023-07-25
6431	1744	372.60	withdrawal	2023-09-19
6432	1203	203.60	deposit	2023-01-17
6433	454	134.70	withdrawal	2023-05-18
6434	780	384.90	withdrawal	2023-05-08
6435	1506	299.60	deposit	2023-04-04
6436	300	302.90	deposit	2023-08-01
6437	120	267.40	deposit	2024-01-26
6438	76	234.80	withdrawal	2024-03-05
6439	255	435.70	withdrawal	2024-01-04
6440	603	345.00	deposit	2024-03-19
6441	665	400.10	withdrawal	2023-04-23
6442	693	21.90	withdrawal	2024-05-07
6443	1348	267.10	withdrawal	2023-02-01
6444	403	225.50	deposit	2023-01-29
6445	3	450.10	deposit	2023-10-16
6446	447	241.70	withdrawal	2023-05-05
6447	424	202.50	deposit	2023-07-30
6448	1794	408.30	withdrawal	2023-12-11
6449	1386	383.90	deposit	2023-08-01
6450	1606	372.00	deposit	2023-04-30
6451	470	441.20	deposit	2023-04-07
6452	293	286.90	deposit	2024-05-04
6453	1789	62.80	deposit	2023-12-28
6454	1616	7.50	withdrawal	2023-11-30
6455	148	239.00	withdrawal	2023-11-03
6456	1023	87.70	deposit	2024-02-15
6457	1080	19.10	deposit	2023-03-11
6458	20	74.60	withdrawal	2023-10-15
6459	50	23.00	withdrawal	2023-10-17
6460	800	11.60	deposit	2023-12-17
6461	199	68.60	deposit	2023-07-22
6462	603	485.50	withdrawal	2023-12-11
6463	1222	485.00	deposit	2023-08-19
6464	1127	123.70	deposit	2024-02-11
6465	992	57.40	withdrawal	2024-05-15
6466	1442	66.60	withdrawal	2023-07-07
6467	439	385.90	withdrawal	2024-02-25
6468	1594	393.80	withdrawal	2024-02-03
6469	100	167.90	withdrawal	2024-02-16
6470	270	92.50	deposit	2023-10-04
6471	553	272.00	withdrawal	2024-02-24
6472	518	432.00	withdrawal	2023-08-31
6473	635	301.80	withdrawal	2023-05-19
6474	1798	26.80	deposit	2023-10-04
6475	386	371.20	withdrawal	2023-07-21
6476	33	14.70	withdrawal	2024-04-28
6477	1033	439.00	withdrawal	2024-02-07
6478	243	85.10	deposit	2023-10-23
6479	1567	135.90	withdrawal	2023-08-22
6480	799	41.20	deposit	2023-06-08
6481	633	134.20	withdrawal	2023-07-01
6482	1626	71.80	deposit	2023-11-22
6483	1417	133.60	deposit	2023-12-19
6484	4	337.00	deposit	2024-05-15
6485	1125	175.40	deposit	2023-05-03
6486	55	219.40	deposit	2024-03-22
6487	696	158.70	deposit	2023-06-28
6488	760	242.90	deposit	2024-05-21
6489	1671	25.20	withdrawal	2023-05-25
6490	690	171.30	withdrawal	2024-03-23
6491	418	101.10	withdrawal	2024-01-08
6492	934	303.80	withdrawal	2023-12-21
6493	181	272.20	deposit	2023-03-25
6494	1619	300.50	withdrawal	2024-04-18
6495	1022	451.10	withdrawal	2023-08-10
6496	1603	328.30	deposit	2023-05-08
6497	676	339.30	withdrawal	2024-01-18
6498	441	18.70	withdrawal	2024-02-19
6499	236	236.10	withdrawal	2024-05-25
6500	480	259.50	deposit	2023-01-16
6501	357	469.10	withdrawal	2023-07-06
6502	315	497.40	withdrawal	2023-07-04
6503	1788	110.20	withdrawal	2023-07-15
6504	829	223.70	withdrawal	2024-02-16
6505	1293	399.00	withdrawal	2023-05-18
6506	1765	153.50	withdrawal	2024-04-06
6507	710	64.90	deposit	2023-07-11
6508	542	141.70	deposit	2024-02-26
6509	1146	496.80	withdrawal	2024-04-29
6510	1055	244.50	deposit	2024-02-18
6511	121	471.40	withdrawal	2023-01-12
6512	251	169.80	withdrawal	2023-08-08
6513	649	365.70	withdrawal	2024-01-13
6514	882	418.80	deposit	2024-01-19
6515	231	448.60	deposit	2023-01-15
6516	468	217.60	withdrawal	2023-06-10
6517	777	40.00	withdrawal	2023-02-06
6518	854	289.80	deposit	2023-07-06
6519	139	384.30	deposit	2023-02-03
6520	258	224.80	withdrawal	2023-02-03
6521	447	468.80	deposit	2023-04-23
6522	1065	429.50	deposit	2023-05-17
6523	218	375.30	deposit	2023-12-19
6524	1594	191.80	withdrawal	2023-07-22
6525	1257	126.20	withdrawal	2024-03-16
6526	580	416.80	withdrawal	2023-12-23
6527	1090	329.40	deposit	2024-04-28
6528	531	237.90	withdrawal	2024-04-21
6529	1169	410.90	deposit	2023-08-29
6530	175	330.30	deposit	2023-04-10
6531	430	20.80	deposit	2023-12-04
6532	72	37.80	deposit	2023-07-17
6533	907	430.70	deposit	2023-07-10
6534	1788	245.20	withdrawal	2024-05-07
6535	1082	54.00	deposit	2024-04-23
6536	944	391.80	withdrawal	2024-01-22
6537	818	232.70	withdrawal	2023-07-12
6538	870	124.90	withdrawal	2023-05-19
6539	149	473.40	deposit	2023-11-26
6540	1030	435.20	withdrawal	2024-05-11
6541	1051	66.30	deposit	2023-04-14
6542	738	439.10	withdrawal	2024-01-02
6543	1745	322.00	deposit	2023-09-16
6544	684	266.90	deposit	2023-03-24
6545	638	360.00	deposit	2023-05-06
6546	1610	254.70	deposit	2024-03-29
6547	1554	86.30	deposit	2023-12-02
6548	1257	193.50	withdrawal	2024-02-25
6549	1516	490.10	deposit	2023-02-04
6550	1668	471.60	withdrawal	2023-10-06
6551	1004	151.40	withdrawal	2024-03-29
6552	925	91.70	deposit	2023-10-16
6553	219	338.70	deposit	2023-11-10
6554	477	264.50	deposit	2024-04-16
6555	46	368.90	withdrawal	2023-02-09
6556	242	354.80	deposit	2024-03-24
6557	1688	321.60	withdrawal	2023-02-11
6558	1724	57.30	deposit	2023-07-23
6559	823	88.50	withdrawal	2023-03-15
6560	1004	208.50	withdrawal	2024-02-08
6561	1401	499.30	deposit	2024-04-23
6562	1575	275.70	deposit	2023-03-26
6563	588	72.20	deposit	2023-12-29
6564	40	241.30	deposit	2023-11-29
6565	538	319.00	deposit	2023-09-28
6566	171	233.70	withdrawal	2023-10-14
6567	1600	387.80	deposit	2023-07-12
6568	313	431.90	withdrawal	2023-10-22
6569	23	23.20	deposit	2023-06-15
6570	1066	150.20	withdrawal	2023-08-04
6571	693	359.00	deposit	2023-11-17
6572	1016	237.10	withdrawal	2023-09-28
6573	646	188.50	withdrawal	2023-11-18
6574	470	405.90	deposit	2024-02-05
6575	933	380.60	deposit	2023-12-18
6576	777	312.30	withdrawal	2023-01-24
6577	136	189.40	deposit	2023-05-11
6578	815	118.10	deposit	2023-01-20
6579	154	80.60	deposit	2023-06-14
6580	1685	224.90	withdrawal	2024-05-28
6581	1152	214.40	withdrawal	2023-09-05
6582	455	81.20	deposit	2023-09-27
6583	259	227.80	deposit	2024-02-24
6584	1575	281.40	withdrawal	2024-01-19
6585	1796	279.30	withdrawal	2023-09-30
6586	1792	45.80	withdrawal	2023-03-30
6587	1678	111.30	deposit	2023-07-31
6588	1286	422.70	deposit	2024-03-20
6589	1593	455.80	deposit	2023-10-24
6590	598	364.60	withdrawal	2024-05-27
6591	1626	432.20	deposit	2023-08-21
6592	115	228.00	withdrawal	2023-11-18
6593	677	354.50	withdrawal	2024-03-14
6594	783	222.40	withdrawal	2023-01-29
6595	926	326.80	deposit	2024-03-07
6596	84	391.70	deposit	2024-04-26
6597	886	415.70	deposit	2024-05-14
6598	1742	270.50	withdrawal	2023-05-04
6599	1767	366.80	withdrawal	2023-03-31
6600	189	94.30	withdrawal	2023-03-28
6601	731	289.60	withdrawal	2023-12-15
6602	273	135.50	deposit	2023-06-08
6603	1520	376.00	deposit	2023-04-23
6604	1018	494.90	withdrawal	2023-04-23
6605	588	167.90	deposit	2023-05-29
6606	1336	120.70	withdrawal	2023-12-12
6607	755	244.90	deposit	2023-05-29
6608	1530	208.40	withdrawal	2023-11-02
6609	1511	277.20	deposit	2024-01-30
6610	98	342.90	deposit	2023-02-14
6611	141	304.10	deposit	2023-04-02
6612	238	164.40	withdrawal	2023-02-15
6613	431	276.80	withdrawal	2024-02-12
6614	1234	17.20	withdrawal	2023-02-09
6615	166	484.30	deposit	2023-08-23
6616	1663	26.90	deposit	2023-05-07
6617	292	355.90	withdrawal	2024-05-11
6618	625	453.70	withdrawal	2024-02-01
6619	1331	349.40	deposit	2024-02-29
6620	1611	416.60	withdrawal	2023-08-08
6621	373	69.60	deposit	2023-07-20
6622	1738	477.10	withdrawal	2023-08-16
6623	1007	84.50	withdrawal	2023-12-18
6624	1339	365.50	withdrawal	2023-01-27
6625	551	321.30	deposit	2023-12-14
6626	1281	431.30	deposit	2023-03-26
6627	1247	85.50	deposit	2024-02-04
6628	1460	98.90	withdrawal	2023-12-23
6629	406	413.70	withdrawal	2023-12-27
6630	1233	344.40	withdrawal	2023-01-22
6631	998	108.80	deposit	2023-01-06
6632	273	318.80	deposit	2023-08-10
6633	234	469.30	deposit	2024-01-01
6634	152	100.00	withdrawal	2023-05-07
6635	1749	400.00	withdrawal	2024-01-25
6636	264	458.00	deposit	2023-10-07
6637	626	47.90	withdrawal	2023-10-12
6638	1744	13.40	deposit	2024-03-30
6639	131	68.00	deposit	2023-09-19
6640	46	387.80	deposit	2023-11-09
6641	1129	351.00	withdrawal	2024-03-21
6642	1474	414.30	withdrawal	2023-01-26
6643	299	347.40	withdrawal	2023-10-29
6644	1044	153.50	deposit	2023-09-29
6645	1391	298.90	withdrawal	2023-12-17
6646	1249	303.10	withdrawal	2023-01-20
6647	28	105.20	withdrawal	2023-12-23
6648	1351	208.30	withdrawal	2024-03-16
6649	126	169.40	deposit	2023-07-31
6650	1147	354.40	withdrawal	2023-03-31
6651	1308	178.30	deposit	2023-05-10
6652	1747	106.90	deposit	2023-08-19
6653	154	310.40	deposit	2023-06-13
6654	8	486.30	withdrawal	2023-06-29
6655	742	231.90	withdrawal	2023-11-30
6656	483	328.40	deposit	2024-03-09
6657	146	148.50	deposit	2023-01-01
6658	1347	192.80	withdrawal	2023-04-17
6659	385	304.80	deposit	2023-05-20
6660	1543	332.30	deposit	2024-05-20
6661	559	462.20	deposit	2023-04-12
6662	1058	74.20	deposit	2024-03-22
6663	316	34.30	deposit	2023-01-30
6664	496	382.60	deposit	2023-10-16
6665	1639	434.40	withdrawal	2023-04-14
6666	145	43.10	withdrawal	2023-05-23
6667	1022	273.90	deposit	2023-08-26
6668	295	143.00	withdrawal	2023-01-16
6669	103	339.70	withdrawal	2023-11-14
6670	650	307.90	deposit	2023-01-16
6671	576	115.20	deposit	2023-03-20
6672	1669	431.70	deposit	2023-05-05
6673	1568	290.70	withdrawal	2023-07-03
6674	494	133.10	withdrawal	2023-08-11
6675	1448	311.60	deposit	2023-08-29
6676	236	308.10	deposit	2024-02-17
6677	585	7.60	deposit	2024-02-03
6678	1161	400.70	withdrawal	2024-05-08
6679	1515	270.90	withdrawal	2023-11-18
6680	130	330.10	withdrawal	2023-11-13
6681	1582	175.30	deposit	2023-07-21
6682	673	301.50	deposit	2023-06-01
6683	348	110.30	withdrawal	2023-11-08
6684	1086	197.20	deposit	2024-02-11
6685	726	17.40	withdrawal	2023-09-13
6686	1340	323.00	withdrawal	2024-01-12
6687	553	480.90	withdrawal	2023-03-05
6688	1376	434.10	withdrawal	2024-02-20
6689	466	378.00	deposit	2024-05-31
6690	458	56.50	deposit	2023-03-27
6691	546	421.50	deposit	2023-07-18
6692	328	289.40	deposit	2023-08-31
6693	650	202.60	deposit	2024-01-07
6694	111	149.10	deposit	2023-07-11
6695	468	61.10	withdrawal	2023-09-18
6696	1156	286.30	withdrawal	2023-11-09
6697	377	427.90	withdrawal	2023-10-05
6698	1633	203.70	deposit	2023-12-05
6699	1772	275.80	deposit	2023-04-17
6700	1292	424.20	withdrawal	2023-03-23
6701	721	433.00	withdrawal	2023-06-19
6702	1524	453.20	withdrawal	2023-12-26
6703	538	273.10	deposit	2023-06-30
6704	1361	83.50	withdrawal	2023-04-15
6705	1480	261.30	withdrawal	2024-02-15
6706	1580	163.70	deposit	2023-08-14
6707	1443	346.10	withdrawal	2023-05-14
6708	199	42.50	deposit	2023-03-21
6709	1510	408.50	deposit	2023-06-22
6710	986	379.30	withdrawal	2023-12-01
6711	483	445.90	withdrawal	2023-10-08
6712	297	6.50	withdrawal	2024-03-26
6713	155	336.10	deposit	2023-09-27
6714	1170	346.60	withdrawal	2023-01-16
6715	380	184.40	withdrawal	2023-02-19
6716	1149	202.40	deposit	2024-03-19
6717	1256	353.60	withdrawal	2023-03-26
6718	559	410.80	withdrawal	2024-05-29
6719	1728	21.00	withdrawal	2023-04-06
6720	107	299.80	withdrawal	2024-01-02
6721	77	402.20	deposit	2023-05-08
6722	1175	21.50	withdrawal	2023-02-16
6723	1557	484.00	deposit	2023-05-17
6724	1566	336.20	withdrawal	2024-04-15
6725	1151	48.80	withdrawal	2023-06-01
6726	546	338.80	deposit	2024-04-22
6727	393	465.10	withdrawal	2023-10-21
6728	575	198.90	deposit	2024-01-27
6729	587	130.30	deposit	2023-10-25
6730	635	45.20	withdrawal	2023-04-29
6731	1677	166.00	deposit	2023-03-07
6732	1282	199.50	withdrawal	2023-05-08
6733	922	365.20	withdrawal	2023-01-12
6734	867	452.30	withdrawal	2024-05-29
6735	768	253.60	withdrawal	2023-07-09
6736	877	82.30	withdrawal	2023-10-07
6737	1492	260.30	withdrawal	2023-06-27
6738	708	8.00	deposit	2024-05-18
6739	769	345.60	withdrawal	2024-01-22
6740	1470	332.50	withdrawal	2024-05-04
6741	1593	160.40	withdrawal	2023-01-30
6742	1319	306.30	deposit	2024-02-17
6743	832	328.00	deposit	2023-09-07
6744	206	315.70	withdrawal	2023-04-19
6745	361	446.10	deposit	2023-02-21
6746	1042	70.20	withdrawal	2024-01-20
6747	1711	130.40	withdrawal	2024-02-08
6748	134	349.50	withdrawal	2023-01-12
6749	1080	316.10	deposit	2023-09-03
6750	41	207.70	deposit	2023-03-19
6751	803	297.60	deposit	2024-04-15
6752	1233	134.30	deposit	2023-03-29
6753	240	150.10	withdrawal	2023-01-26
6754	316	381.50	withdrawal	2023-09-27
6755	1078	357.70	withdrawal	2023-08-18
6756	1414	18.40	withdrawal	2023-10-31
6757	1718	464.20	deposit	2023-02-18
6758	1450	213.10	withdrawal	2023-05-14
6759	1739	495.10	deposit	2023-06-09
6760	1074	439.80	withdrawal	2023-04-11
6761	1205	439.40	withdrawal	2023-09-17
6762	669	454.40	deposit	2023-04-19
6763	91	35.10	withdrawal	2023-06-02
6764	487	31.30	withdrawal	2023-08-08
6765	1261	125.60	deposit	2024-01-11
6766	1062	290.80	withdrawal	2023-08-23
6767	1640	352.50	withdrawal	2023-11-22
6768	1667	319.90	deposit	2023-02-26
6769	1319	428.40	withdrawal	2024-04-27
6770	207	275.90	deposit	2023-02-02
6771	1331	62.00	deposit	2023-12-08
6772	1647	45.20	deposit	2023-02-15
6773	1476	96.20	withdrawal	2024-02-16
6774	990	411.70	deposit	2024-04-02
6775	1460	198.80	withdrawal	2023-11-19
6776	812	378.20	deposit	2023-10-31
6777	1282	455.90	withdrawal	2023-06-25
6778	1794	285.90	withdrawal	2023-05-10
6779	621	171.80	deposit	2024-01-23
6780	1224	439.00	withdrawal	2023-08-21
6781	773	485.80	deposit	2023-12-22
6782	1495	297.20	withdrawal	2023-01-12
6783	1785	406.80	withdrawal	2023-06-17
6784	503	394.40	deposit	2023-05-15
6785	270	296.20	withdrawal	2023-03-14
6786	603	95.60	deposit	2023-12-01
6787	95	250.80	withdrawal	2024-01-31
6788	1387	302.50	withdrawal	2024-02-03
6789	1697	114.20	deposit	2023-06-12
6790	913	279.10	deposit	2023-01-16
6791	328	75.50	deposit	2023-09-02
6792	881	411.70	withdrawal	2023-09-29
6793	696	364.60	withdrawal	2023-02-05
6794	892	272.40	deposit	2024-03-25
6795	1764	453.90	deposit	2024-01-05
6796	431	206.20	withdrawal	2023-01-08
6797	571	414.10	deposit	2023-11-14
6798	1505	495.50	withdrawal	2024-04-12
6799	660	500.40	withdrawal	2023-01-20
6800	1648	36.90	deposit	2023-01-03
6801	966	202.60	withdrawal	2023-10-30
6802	1342	65.30	withdrawal	2023-05-12
6803	1338	47.70	deposit	2023-04-15
6804	1580	45.90	deposit	2023-04-21
6805	785	421.00	deposit	2024-04-09
6806	1202	51.90	deposit	2024-03-25
6807	717	478.40	deposit	2024-05-26
6808	932	234.10	deposit	2023-07-07
6809	25	233.30	deposit	2024-05-06
6810	216	452.50	deposit	2023-01-13
6811	729	42.10	deposit	2024-03-07
6812	20	355.10	deposit	2023-11-15
6813	754	374.60	withdrawal	2024-02-11
6814	1057	456.20	deposit	2023-10-03
6815	98	20.30	deposit	2023-05-07
6816	664	420.60	deposit	2023-09-20
6817	54	121.90	deposit	2023-04-22
6818	443	132.00	deposit	2023-10-10
6819	773	230.90	withdrawal	2024-01-08
6820	1752	146.10	withdrawal	2023-09-16
6821	551	265.30	withdrawal	2023-08-05
6822	673	33.70	deposit	2023-03-16
6823	966	154.80	deposit	2024-04-22
6824	1298	146.20	withdrawal	2023-11-28
6825	243	75.30	deposit	2023-04-14
6826	154	96.80	withdrawal	2023-05-05
6827	1384	80.60	withdrawal	2023-08-06
6828	1678	81.70	withdrawal	2023-08-03
6829	212	452.20	withdrawal	2024-01-29
6830	1579	227.20	deposit	2023-11-10
6831	1504	40.80	withdrawal	2023-04-05
6832	676	476.40	withdrawal	2023-11-20
6833	116	9.10	deposit	2024-05-26
6834	91	80.30	withdrawal	2023-04-20
6835	823	496.50	withdrawal	2023-10-23
6836	1033	441.60	deposit	2023-11-17
6837	1547	21.00	withdrawal	2024-01-19
6838	1754	450.60	withdrawal	2023-07-15
6839	1247	484.10	deposit	2023-01-17
6840	1800	385.90	withdrawal	2023-02-21
6841	765	390.40	deposit	2024-01-31
6842	1075	383.50	deposit	2023-01-29
6843	1166	64.20	deposit	2023-02-10
6844	80	411.50	deposit	2023-09-01
6845	796	256.70	withdrawal	2023-05-20
6846	138	394.70	deposit	2024-03-05
6847	147	384.80	deposit	2023-04-01
6848	105	362.00	deposit	2024-04-29
6849	176	53.00	deposit	2023-09-29
6850	1397	396.20	withdrawal	2023-10-17
6851	780	156.30	deposit	2023-08-09
6852	675	129.80	deposit	2023-04-13
6853	475	206.10	deposit	2023-02-27
6854	1192	222.40	deposit	2023-07-18
6855	1092	324.60	withdrawal	2023-04-14
6856	1237	365.40	withdrawal	2023-01-27
6857	1187	71.40	withdrawal	2023-03-27
6858	156	399.30	deposit	2024-04-26
6859	194	203.50	withdrawal	2023-01-13
6860	198	447.20	withdrawal	2024-01-25
6861	311	123.00	withdrawal	2023-09-25
6862	1470	51.20	withdrawal	2023-06-25
6863	267	345.80	deposit	2023-12-18
6864	1319	43.90	withdrawal	2023-06-14
6865	160	116.40	withdrawal	2023-08-23
6866	127	451.30	deposit	2023-10-28
6867	878	54.60	deposit	2024-02-29
6868	133	37.60	deposit	2023-10-20
6869	1762	316.60	deposit	2023-02-24
6870	947	433.30	withdrawal	2024-05-26
6871	166	195.50	deposit	2023-07-23
6872	680	470.80	withdrawal	2023-02-21
6873	262	211.60	withdrawal	2023-06-25
6874	324	416.20	withdrawal	2023-05-06
6875	677	209.80	deposit	2023-10-23
6876	87	493.40	withdrawal	2023-06-13
6877	142	68.40	deposit	2024-03-25
6878	136	264.30	withdrawal	2023-11-26
6879	1789	437.20	deposit	2023-01-31
6880	458	279.30	withdrawal	2023-10-25
6881	440	29.50	withdrawal	2024-05-29
6882	612	116.80	deposit	2023-04-11
6883	1193	301.40	withdrawal	2024-03-05
6884	1337	353.90	deposit	2023-05-11
6885	1292	252.40	deposit	2023-06-28
6886	408	201.00	withdrawal	2024-03-14
6887	1596	374.20	deposit	2023-11-29
6888	1344	172.40	deposit	2024-03-18
6889	436	6.30	withdrawal	2024-03-08
6890	864	432.10	withdrawal	2023-08-30
6891	109	268.70	deposit	2023-05-18
6892	816	431.60	withdrawal	2023-10-13
6893	1089	95.60	withdrawal	2023-11-30
6894	608	153.40	withdrawal	2023-07-14
6895	455	365.00	withdrawal	2023-01-28
6896	507	93.50	deposit	2024-03-22
6897	440	494.80	withdrawal	2023-12-12
6898	1639	329.30	deposit	2024-01-11
6899	743	176.10	withdrawal	2023-03-05
6900	229	240.50	deposit	2023-01-25
6901	354	120.40	deposit	2024-01-25
6902	1555	273.80	deposit	2023-03-23
6903	1381	56.90	deposit	2023-08-01
6904	1066	397.10	deposit	2024-03-19
6905	667	463.90	deposit	2023-01-07
6906	1055	215.00	deposit	2023-08-11
6907	1500	26.60	withdrawal	2024-03-03
6908	686	245.10	deposit	2024-04-11
6909	977	131.10	deposit	2024-02-02
6910	992	318.90	deposit	2023-01-23
6911	163	294.40	withdrawal	2023-04-04
6912	365	338.60	withdrawal	2023-11-16
6913	862	349.40	deposit	2023-08-02
6914	1306	14.10	withdrawal	2024-03-04
6915	297	83.60	deposit	2024-05-22
6916	1027	76.20	withdrawal	2023-01-24
6917	1107	160.40	deposit	2023-08-31
6918	116	324.10	withdrawal	2023-01-13
6919	977	93.00	deposit	2024-05-17
6920	1526	325.20	deposit	2023-07-19
6921	896	288.40	deposit	2024-03-16
6922	587	488.40	deposit	2023-08-08
6923	687	496.30	deposit	2023-11-22
6924	1763	382.60	withdrawal	2023-07-24
6925	380	151.90	withdrawal	2024-04-21
6926	535	385.70	deposit	2023-03-28
6927	743	491.50	deposit	2023-05-30
6928	220	95.30	deposit	2023-03-15
6929	1513	20.50	deposit	2023-12-27
6930	1197	67.50	deposit	2024-03-08
6931	1081	261.80	withdrawal	2023-12-19
6932	754	334.40	withdrawal	2023-10-26
6933	541	123.20	withdrawal	2024-01-08
6934	972	391.40	deposit	2023-08-23
6935	1535	68.60	withdrawal	2023-05-20
6936	1734	442.70	withdrawal	2023-11-07
6937	467	32.50	withdrawal	2023-10-24
6938	637	332.30	withdrawal	2024-02-03
6939	292	80.30	deposit	2024-01-23
6940	1088	341.60	deposit	2023-08-27
6941	902	178.70	withdrawal	2023-05-23
6942	853	284.90	withdrawal	2024-03-19
6943	841	17.70	withdrawal	2024-02-03
6944	1454	398.70	withdrawal	2023-02-02
6945	1208	106.60	deposit	2023-06-10
6946	1038	196.40	withdrawal	2024-04-27
6947	918	146.60	deposit	2023-12-19
6948	388	265.70	withdrawal	2024-03-10
6949	1154	377.80	withdrawal	2024-02-18
6950	148	137.10	withdrawal	2023-02-09
6951	106	340.90	withdrawal	2023-03-03
6952	1239	58.60	deposit	2023-03-19
6953	471	410.50	withdrawal	2023-08-09
6954	378	73.40	withdrawal	2024-02-12
6955	5	180.90	deposit	2023-10-04
6956	1297	153.70	withdrawal	2023-03-16
6957	992	284.80	deposit	2023-07-24
6958	278	397.50	withdrawal	2023-05-27
6959	1527	13.20	withdrawal	2023-03-15
6960	1527	128.20	withdrawal	2023-07-14
6961	641	444.80	deposit	2023-01-09
6962	522	278.40	deposit	2023-05-20
6963	1238	454.50	withdrawal	2023-06-05
6964	99	106.60	deposit	2023-01-23
6965	67	225.80	withdrawal	2023-11-01
6966	387	63.90	deposit	2023-04-30
6967	739	151.70	deposit	2023-11-27
6968	1517	9.40	deposit	2023-03-19
6969	1132	166.60	withdrawal	2023-01-28
6970	1331	383.80	deposit	2023-07-29
6971	1075	317.70	deposit	2023-11-21
6972	1370	426.20	deposit	2023-08-31
6973	1319	70.60	withdrawal	2024-03-11
6974	1351	141.00	withdrawal	2023-07-05
6975	737	259.30	deposit	2024-03-26
6976	1683	118.10	deposit	2023-09-08
6977	826	482.80	deposit	2024-01-05
6978	552	308.40	deposit	2023-06-04
6979	68	37.90	deposit	2024-03-31
6980	1776	131.10	withdrawal	2024-04-02
6981	1027	353.00	deposit	2023-09-13
6982	1287	147.70	deposit	2023-04-24
6983	673	289.70	withdrawal	2024-04-22
6984	1268	454.90	deposit	2023-11-03
6985	962	358.20	deposit	2024-05-09
6986	1538	466.60	deposit	2024-01-07
6987	529	233.60	withdrawal	2023-12-09
6988	1694	424.50	withdrawal	2023-10-04
6989	418	90.40	withdrawal	2024-04-02
6990	1097	261.90	withdrawal	2024-02-20
6991	63	494.70	deposit	2024-04-15
6992	901	273.30	withdrawal	2023-11-27
6993	1166	84.90	withdrawal	2023-04-22
6994	547	131.90	deposit	2023-02-03
6995	1306	14.80	withdrawal	2023-01-07
6996	334	238.20	withdrawal	2024-01-07
6997	112	53.30	deposit	2024-04-20
6998	1364	106.90	withdrawal	2024-05-01
6999	522	427.30	deposit	2024-01-24
7000	324	472.00	withdrawal	2023-05-15
7001	570	336.60	deposit	2023-06-07
7002	738	42.30	withdrawal	2024-05-24
7003	195	145.40	deposit	2024-02-06
7004	734	120.10	deposit	2024-04-14
7005	733	12.30	withdrawal	2023-05-22
7006	181	27.80	withdrawal	2023-05-11
7007	1316	308.10	withdrawal	2023-05-15
7008	120	334.90	withdrawal	2023-08-30
7009	798	277.30	withdrawal	2023-03-22
7010	1503	487.20	withdrawal	2024-04-03
7011	367	469.00	deposit	2023-09-05
7012	743	383.30	withdrawal	2023-06-02
7013	580	229.10	withdrawal	2023-08-14
7014	1154	172.70	deposit	2023-06-01
7015	178	291.60	deposit	2023-02-20
7016	110	94.90	deposit	2024-04-15
7017	721	500.20	deposit	2023-02-17
7018	1326	390.90	deposit	2023-02-13
7019	947	63.20	withdrawal	2023-08-23
7020	162	415.60	withdrawal	2024-01-10
7021	1104	369.60	deposit	2023-01-04
7022	1592	414.80	deposit	2023-12-21
7023	15	476.00	deposit	2023-01-14
7024	844	346.60	deposit	2023-10-15
7025	1177	138.90	deposit	2023-03-22
7026	141	143.80	deposit	2023-05-02
7027	763	290.20	withdrawal	2023-05-09
7028	881	291.70	deposit	2023-05-29
7029	1300	361.50	withdrawal	2023-07-23
7030	243	301.60	deposit	2023-12-16
7031	35	156.90	withdrawal	2024-02-11
7032	819	315.10	deposit	2023-09-04
7033	1475	500.40	deposit	2023-02-17
7034	565	428.00	withdrawal	2023-06-28
7035	1257	285.50	deposit	2023-06-05
7036	1166	98.00	withdrawal	2023-10-29
7037	933	378.40	withdrawal	2024-01-25
7038	734	90.10	withdrawal	2023-06-08
7039	1672	128.10	deposit	2024-01-18
7040	198	446.60	withdrawal	2023-05-05
7041	257	385.30	deposit	2023-08-11
7042	332	474.10	withdrawal	2023-06-03
7043	972	474.50	deposit	2024-04-04
7044	962	243.30	withdrawal	2024-02-14
7045	19	438.30	deposit	2023-01-30
7046	1708	416.10	withdrawal	2024-02-07
7047	1337	287.60	withdrawal	2023-04-02
7048	217	201.90	withdrawal	2023-03-12
7049	744	142.00	deposit	2023-08-02
7050	1469	56.00	withdrawal	2023-08-31
7051	297	21.20	deposit	2024-01-12
7052	36	222.80	deposit	2023-04-27
7053	1433	31.90	withdrawal	2023-08-23
7054	987	320.30	deposit	2024-02-18
7055	1345	466.50	withdrawal	2023-10-27
7056	1534	282.80	withdrawal	2023-04-11
7057	327	413.50	deposit	2023-10-22
7058	1394	339.00	deposit	2023-12-17
7059	1156	14.90	deposit	2023-11-21
7060	1521	54.10	withdrawal	2023-04-23
7061	1097	5.30	deposit	2023-05-19
7062	466	142.60	withdrawal	2023-03-06
7063	1122	270.00	deposit	2024-02-28
7064	615	105.20	deposit	2024-05-05
7065	619	76.10	withdrawal	2023-11-24
7066	135	449.40	withdrawal	2024-02-29
7067	364	171.60	withdrawal	2023-08-13
7068	1129	141.10	withdrawal	2024-05-30
7069	1461	140.00	withdrawal	2023-09-20
7070	952	35.60	withdrawal	2024-04-16
7071	361	362.40	deposit	2023-02-21
7072	168	434.80	deposit	2023-09-03
7073	1395	186.80	deposit	2023-10-19
7074	1773	31.20	deposit	2023-06-08
7075	1636	166.60	withdrawal	2023-06-20
7076	369	145.80	withdrawal	2024-01-26
7077	919	487.50	deposit	2023-05-20
7078	334	314.60	deposit	2023-12-24
7079	642	315.10	deposit	2023-11-26
7080	1230	158.40	withdrawal	2023-04-09
7081	1016	498.10	deposit	2023-09-13
7082	144	160.30	deposit	2023-02-05
7083	132	276.00	withdrawal	2024-02-08
7084	183	153.10	deposit	2024-04-24
7085	1709	309.10	withdrawal	2023-08-21
7086	1216	46.70	withdrawal	2023-04-28
7087	264	178.50	withdrawal	2023-12-27
7088	808	437.00	deposit	2024-05-13
7089	296	45.00	withdrawal	2023-10-30
7090	180	267.60	withdrawal	2023-03-06
7091	1636	21.20	deposit	2023-08-08
7092	1648	282.80	withdrawal	2023-01-12
7093	274	64.20	deposit	2023-10-17
7094	1360	430.10	withdrawal	2023-07-11
7095	227	179.10	withdrawal	2024-01-18
7096	1526	167.20	deposit	2023-09-18
7097	258	362.20	withdrawal	2023-03-24
7098	14	439.60	withdrawal	2023-11-13
7099	720	246.50	deposit	2024-04-04
7100	1080	182.00	deposit	2023-03-18
7101	802	56.50	withdrawal	2023-06-09
7102	766	96.70	withdrawal	2023-03-02
7103	1077	35.20	deposit	2023-06-14
7104	298	350.40	withdrawal	2024-05-05
7105	984	9.90	deposit	2024-03-08
7106	1779	142.60	withdrawal	2023-05-11
7107	682	392.50	withdrawal	2024-02-16
7108	312	123.30	deposit	2023-01-09
7109	1201	335.50	deposit	2023-01-01
7110	1209	462.90	deposit	2023-12-17
7111	1452	280.30	withdrawal	2024-02-28
7112	15	37.70	withdrawal	2023-12-09
7113	4	405.00	withdrawal	2023-01-01
7114	1405	281.10	withdrawal	2023-03-20
7115	732	375.50	deposit	2024-01-24
7116	1194	295.60	withdrawal	2023-09-25
7117	527	113.40	deposit	2024-04-21
7118	785	306.40	deposit	2024-04-22
7119	1777	236.00	deposit	2024-01-23
7120	530	30.20	deposit	2023-06-18
7121	140	240.40	withdrawal	2023-07-13
7122	1098	27.40	deposit	2024-01-20
7123	538	19.70	deposit	2024-02-11
7124	441	429.30	deposit	2023-12-19
7125	1392	205.40	withdrawal	2024-04-17
7126	42	295.00	withdrawal	2024-01-19
7127	991	414.50	withdrawal	2024-01-01
7128	1655	399.00	deposit	2023-07-10
7129	1193	305.00	deposit	2024-03-09
7130	243	446.40	deposit	2024-05-05
7131	679	174.40	deposit	2024-04-14
7132	1358	217.60	withdrawal	2023-02-14
7133	1351	372.00	deposit	2023-10-08
7134	1088	225.10	deposit	2023-02-15
7135	1708	106.90	withdrawal	2023-11-28
7136	296	467.40	withdrawal	2023-05-02
7137	21	36.50	withdrawal	2024-03-17
7138	652	279.00	withdrawal	2024-03-07
7139	345	479.00	withdrawal	2024-04-28
7140	1350	100.10	deposit	2023-04-29
7141	1743	97.40	deposit	2024-02-19
7142	1696	103.30	withdrawal	2024-05-13
7143	732	456.90	deposit	2023-06-19
7144	1367	215.20	withdrawal	2023-07-22
7145	17	131.50	deposit	2023-01-25
7146	1112	300.00	deposit	2023-03-29
7147	1274	412.30	deposit	2023-09-16
7148	1690	269.10	deposit	2024-05-17
7149	201	9.50	withdrawal	2023-08-02
7150	817	248.10	deposit	2024-01-23
7151	1103	355.00	withdrawal	2023-02-24
7152	1268	359.70	deposit	2023-02-03
7153	554	137.20	withdrawal	2023-10-25
7154	252	319.30	deposit	2023-05-06
7155	1078	132.60	withdrawal	2024-05-30
7156	1340	329.70	withdrawal	2023-12-10
7157	1258	331.50	withdrawal	2023-08-11
7158	1571	63.50	withdrawal	2023-12-14
7159	981	65.30	withdrawal	2024-02-23
7160	109	297.60	deposit	2023-02-03
7161	815	185.60	deposit	2024-05-22
7162	1419	494.00	withdrawal	2023-03-21
7163	1709	477.60	withdrawal	2023-10-25
7164	198	499.80	deposit	2023-06-18
7165	1317	445.60	withdrawal	2024-02-23
7166	1031	449.80	withdrawal	2023-10-25
7167	379	115.80	withdrawal	2023-12-09
7168	89	469.90	withdrawal	2023-08-13
7169	486	107.90	deposit	2024-04-20
7170	1726	488.20	withdrawal	2023-09-23
7171	704	477.50	withdrawal	2024-03-13
7172	1086	84.60	deposit	2023-06-25
7173	862	279.40	withdrawal	2024-04-04
7174	175	435.90	withdrawal	2023-06-06
7175	163	315.10	deposit	2023-12-05
7176	606	319.80	withdrawal	2024-02-05
7177	956	83.70	deposit	2024-05-25
7178	1579	265.00	deposit	2024-03-14
7179	315	239.20	withdrawal	2023-05-19
7180	1477	185.60	deposit	2023-06-03
7181	1043	102.40	withdrawal	2023-11-06
7182	233	233.00	withdrawal	2023-12-25
7183	553	32.20	withdrawal	2024-04-21
7184	991	304.70	deposit	2023-12-30
7185	841	210.20	deposit	2024-05-26
7186	306	378.80	deposit	2024-03-01
7187	1481	140.00	deposit	2023-05-22
7188	1106	21.80	withdrawal	2023-10-21
7189	828	157.50	deposit	2023-07-20
7190	1767	274.90	withdrawal	2023-03-29
7191	1263	296.40	withdrawal	2023-05-22
7192	1122	435.40	withdrawal	2023-04-17
7193	1330	61.70	deposit	2023-12-31
7194	72	13.10	deposit	2024-04-23
7195	783	222.00	deposit	2023-11-23
7196	715	232.20	deposit	2023-06-27
7197	143	222.10	deposit	2023-02-02
7198	1295	450.60	deposit	2023-11-25
7199	144	314.30	withdrawal	2023-10-06
7200	240	496.70	withdrawal	2023-06-12
7201	108	479.10	withdrawal	2023-02-03
7202	573	491.30	withdrawal	2023-07-15
7203	1429	402.60	withdrawal	2024-02-08
7204	1490	383.70	withdrawal	2024-01-24
7205	689	487.60	withdrawal	2024-04-26
7206	948	352.30	withdrawal	2023-10-19
7207	1574	256.70	deposit	2024-05-25
7208	552	336.10	withdrawal	2024-03-02
7209	455	453.30	deposit	2023-04-04
7210	493	103.40	withdrawal	2023-03-06
7211	721	238.10	deposit	2024-02-28
7212	803	442.60	withdrawal	2023-07-22
7213	162	6.40	deposit	2023-10-03
7214	1023	460.20	withdrawal	2023-09-10
7215	623	437.80	withdrawal	2024-02-01
7216	608	105.70	withdrawal	2023-05-02
7217	837	230.30	withdrawal	2023-07-17
7218	698	419.00	withdrawal	2023-07-09
7219	1000	155.80	withdrawal	2024-03-09
7220	510	275.00	withdrawal	2023-11-21
7221	1313	270.20	withdrawal	2023-09-13
7222	29	6.00	withdrawal	2023-01-09
7223	1350	187.00	withdrawal	2023-05-30
7224	1053	147.20	withdrawal	2024-02-21
7225	1440	265.30	deposit	2023-07-14
7226	779	444.10	deposit	2023-06-05
7227	320	375.90	deposit	2024-04-25
7228	1474	407.00	withdrawal	2023-12-18
7229	1161	221.20	deposit	2024-01-23
7230	840	38.70	deposit	2023-10-12
7231	443	423.70	withdrawal	2024-01-10
7232	595	381.70	withdrawal	2023-05-31
7233	346	339.90	withdrawal	2024-01-18
7234	1061	322.90	deposit	2023-03-11
7235	1467	299.80	withdrawal	2023-06-12
7236	1168	499.50	withdrawal	2023-07-31
7237	1581	484.10	withdrawal	2023-11-21
7238	516	116.90	deposit	2024-04-17
7239	281	223.70	deposit	2023-08-06
7240	1035	220.00	deposit	2023-12-15
7241	1408	342.60	withdrawal	2023-07-06
7242	464	368.90	withdrawal	2024-04-04
7243	1400	174.50	deposit	2023-01-30
7244	474	270.60	deposit	2024-03-12
7245	837	136.90	withdrawal	2023-01-18
7246	202	324.20	withdrawal	2023-05-17
7247	1663	395.60	deposit	2023-04-13
7248	363	388.40	withdrawal	2023-12-30
7249	795	357.50	withdrawal	2023-06-01
7250	823	21.20	withdrawal	2023-06-14
7251	1216	472.50	deposit	2023-05-04
7252	971	81.30	withdrawal	2023-06-30
7253	504	398.60	deposit	2023-10-28
7254	818	485.70	deposit	2023-03-28
7255	68	122.40	withdrawal	2023-03-04
7256	489	31.30	withdrawal	2024-05-23
7257	1671	406.10	withdrawal	2023-09-07
7258	1065	328.80	withdrawal	2023-06-06
7259	578	179.00	deposit	2023-11-18
7260	598	300.80	deposit	2023-09-18
7261	665	37.30	deposit	2024-05-17
7262	1176	217.30	deposit	2023-04-04
7263	1086	122.40	withdrawal	2024-05-17
7264	901	103.30	withdrawal	2023-11-03
7265	719	126.50	deposit	2024-04-29
7266	719	76.70	deposit	2024-04-25
7267	1145	379.70	deposit	2023-11-16
7268	1335	489.20	withdrawal	2023-11-20
7269	1101	35.80	deposit	2023-01-09
7270	1493	48.30	withdrawal	2023-12-26
7271	1601	40.20	withdrawal	2023-06-22
7272	360	176.70	withdrawal	2023-01-08
7273	614	127.90	deposit	2023-10-11
7274	749	359.40	deposit	2024-03-27
7275	1716	390.10	deposit	2024-03-28
7276	1324	279.10	deposit	2023-12-24
7277	1617	328.10	withdrawal	2023-09-29
7278	668	203.10	withdrawal	2024-04-22
7279	160	306.00	withdrawal	2024-05-09
7280	1287	34.60	deposit	2023-06-17
7281	1659	372.00	withdrawal	2023-05-19
7282	1259	373.00	deposit	2024-05-21
7283	99	109.60	deposit	2024-02-10
7284	1623	358.40	withdrawal	2024-03-25
7285	43	363.20	deposit	2024-05-27
7286	555	183.40	withdrawal	2023-11-26
7287	1785	28.80	deposit	2023-11-18
7288	951	336.00	deposit	2023-11-21
7289	1415	138.80	deposit	2023-10-21
7290	323	282.00	withdrawal	2023-01-25
7291	1184	246.20	withdrawal	2023-12-26
7292	698	105.10	withdrawal	2023-11-23
7293	256	149.10	deposit	2024-03-20
7294	1588	123.70	deposit	2023-02-16
7295	361	408.90	deposit	2024-03-04
7296	98	185.00	withdrawal	2023-12-18
7297	1747	43.40	withdrawal	2023-02-02
7298	875	348.70	withdrawal	2023-05-11
7299	1772	41.20	withdrawal	2023-09-22
7300	470	152.10	withdrawal	2024-01-18
7301	80	211.60	deposit	2024-04-25
7302	268	291.00	withdrawal	2023-03-05
7303	154	408.80	deposit	2024-01-03
7304	304	270.50	deposit	2023-12-28
7305	871	242.80	withdrawal	2023-09-30
7306	1542	196.10	deposit	2023-02-28
7307	1020	369.40	withdrawal	2024-05-23
7308	1353	482.10	withdrawal	2023-01-16
7309	1509	440.40	withdrawal	2024-01-05
7310	534	126.00	deposit	2023-06-06
7311	1511	109.60	deposit	2023-08-11
7312	1001	355.20	deposit	2023-06-20
7313	1787	467.10	deposit	2023-12-06
7314	1466	247.30	deposit	2023-03-23
7315	865	6.20	withdrawal	2023-02-24
7316	1701	406.50	withdrawal	2023-10-30
7317	942	294.90	withdrawal	2023-09-18
7318	86	284.30	withdrawal	2023-06-29
7319	1692	8.00	withdrawal	2023-12-03
7320	911	102.70	deposit	2023-11-11
7321	1545	220.70	deposit	2023-03-30
7322	90	232.90	deposit	2024-03-25
7323	1031	482.20	deposit	2023-01-14
7324	466	384.10	deposit	2024-01-08
7325	828	487.90	withdrawal	2024-01-21
7326	454	207.80	withdrawal	2024-05-18
7327	184	414.50	deposit	2023-12-06
7328	1027	324.70	deposit	2023-05-19
7329	1502	310.70	withdrawal	2024-05-22
7330	1229	45.10	withdrawal	2024-02-26
7331	1532	201.30	deposit	2023-03-01
7332	1450	311.50	withdrawal	2023-12-01
7333	713	392.80	deposit	2024-04-08
7334	412	49.10	deposit	2023-02-27
7335	491	362.00	withdrawal	2024-02-23
7336	1780	75.10	withdrawal	2024-01-12
7337	1482	78.00	withdrawal	2024-03-05
7338	398	122.80	deposit	2023-10-19
7339	38	171.80	withdrawal	2024-01-14
7340	1155	459.50	withdrawal	2023-10-19
7341	574	210.60	deposit	2023-10-03
7342	985	170.00	deposit	2023-07-02
7343	1320	266.10	deposit	2024-05-10
7344	1132	337.60	withdrawal	2023-01-05
7345	1020	348.40	deposit	2023-08-30
7346	641	489.50	withdrawal	2023-08-29
7347	74	374.50	withdrawal	2023-11-04
7348	353	194.10	deposit	2023-09-14
7349	1449	85.50	deposit	2023-06-01
7350	1353	45.70	deposit	2023-04-29
7351	20	469.00	deposit	2023-04-02
7352	269	390.60	deposit	2023-04-03
7353	483	496.00	deposit	2023-11-18
7354	757	442.70	deposit	2023-01-06
7355	429	235.30	withdrawal	2023-04-28
7356	1668	167.30	withdrawal	2023-12-06
7357	1264	219.90	withdrawal	2023-06-26
7358	919	250.90	withdrawal	2023-01-23
7359	851	380.40	withdrawal	2023-10-21
7360	1220	231.60	withdrawal	2023-03-15
7361	1232	267.00	withdrawal	2023-02-26
7362	909	101.90	deposit	2024-04-15
7363	1125	8.90	deposit	2024-03-27
7364	823	146.80	deposit	2023-05-09
7365	528	225.20	deposit	2024-04-18
7366	711	168.30	withdrawal	2024-01-30
7367	983	459.60	deposit	2024-01-23
7368	787	149.00	deposit	2023-12-24
7369	1526	117.40	deposit	2024-04-11
7370	1122	365.70	withdrawal	2023-01-21
7371	89	356.70	deposit	2023-11-26
7372	1734	146.10	withdrawal	2024-02-23
7373	1732	436.10	deposit	2023-08-05
7374	929	481.80	withdrawal	2024-04-10
7375	537	113.60	deposit	2023-05-28
7376	326	467.70	withdrawal	2024-01-23
7377	646	293.60	deposit	2023-12-02
7378	221	219.70	withdrawal	2023-02-11
7379	1535	368.10	deposit	2023-06-23
7380	1242	276.20	withdrawal	2023-09-01
7381	79	235.00	withdrawal	2023-01-06
7382	1698	394.80	deposit	2024-01-12
7383	1706	256.60	withdrawal	2023-11-06
7384	1468	252.90	deposit	2023-06-26
7385	1151	25.20	deposit	2024-01-24
7386	1511	246.50	withdrawal	2023-12-23
7387	837	331.90	withdrawal	2023-05-28
7388	1703	180.90	withdrawal	2023-05-16
7389	1649	341.90	deposit	2023-08-27
7390	1659	430.30	deposit	2023-04-24
7391	434	287.60	withdrawal	2023-08-06
7392	1181	327.40	deposit	2023-01-16
7393	1397	372.10	withdrawal	2023-01-28
7394	827	17.00	withdrawal	2024-01-27
7395	81	193.50	deposit	2023-12-30
7396	690	123.30	withdrawal	2024-03-10
7397	1709	76.40	deposit	2023-05-25
7398	881	352.60	withdrawal	2023-03-05
7399	1241	465.60	withdrawal	2023-07-21
7400	1262	478.60	withdrawal	2023-06-21
7401	1598	468.30	withdrawal	2023-07-06
7402	282	199.40	withdrawal	2024-04-24
7403	1595	222.80	deposit	2023-04-21
7404	238	368.50	withdrawal	2023-04-08
7405	718	312.50	withdrawal	2023-03-12
7406	1283	6.80	deposit	2024-02-11
7407	1499	145.90	withdrawal	2023-04-29
7408	530	356.00	withdrawal	2024-02-12
7409	1274	193.70	deposit	2023-06-16
7410	706	490.20	withdrawal	2023-08-11
7411	695	30.20	withdrawal	2023-11-15
7412	633	417.70	withdrawal	2024-01-01
7413	1707	246.40	deposit	2023-01-28
7414	1522	455.00	withdrawal	2023-06-19
7415	895	84.60	withdrawal	2023-02-23
7416	1281	73.80	withdrawal	2024-04-22
7417	1760	259.80	deposit	2023-07-14
7418	1133	86.40	withdrawal	2023-09-12
7419	1592	331.30	deposit	2023-03-09
7420	1351	373.50	deposit	2023-08-07
7421	644	31.60	deposit	2023-07-14
7422	52	6.10	withdrawal	2023-05-23
7423	203	473.00	withdrawal	2023-09-16
7424	433	449.60	deposit	2023-04-27
7425	957	355.50	withdrawal	2023-05-06
7426	943	367.90	withdrawal	2024-01-22
7427	281	109.30	withdrawal	2023-03-13
7428	324	298.30	withdrawal	2024-04-15
7429	835	272.20	deposit	2023-08-26
7430	78	5.20	deposit	2023-10-06
7431	1773	253.50	deposit	2023-02-23
7432	1783	383.40	deposit	2024-03-08
7433	1408	471.40	deposit	2024-03-11
7434	53	392.70	deposit	2023-06-23
7435	506	172.20	withdrawal	2024-02-26
7436	398	166.00	withdrawal	2023-10-21
7437	1363	38.50	withdrawal	2023-03-18
7438	94	184.00	deposit	2023-04-22
7439	1752	225.20	withdrawal	2023-03-22
7440	938	135.20	withdrawal	2023-12-19
7441	889	309.90	withdrawal	2023-12-01
7442	639	230.00	withdrawal	2024-01-05
7443	1739	24.20	withdrawal	2024-01-05
7444	118	178.00	deposit	2024-02-15
7445	653	162.60	deposit	2023-03-15
7446	570	251.10	deposit	2023-02-14
7447	1498	105.00	withdrawal	2023-04-05
7448	1132	192.00	withdrawal	2023-02-11
7449	1275	430.00	withdrawal	2023-03-10
7450	91	489.50	withdrawal	2023-12-22
7451	1441	21.00	deposit	2023-05-14
7452	1265	182.80	withdrawal	2024-04-21
7453	461	260.70	withdrawal	2023-02-07
7454	565	377.10	deposit	2023-05-19
7455	1112	473.90	deposit	2023-11-17
7456	1116	151.50	withdrawal	2023-01-26
7457	1483	457.40	deposit	2023-12-18
7458	994	159.60	withdrawal	2023-11-27
7459	813	397.80	deposit	2023-02-27
7460	615	329.40	withdrawal	2023-04-08
7461	1440	282.70	deposit	2023-01-25
7462	1252	183.50	withdrawal	2023-05-26
7463	15	85.80	deposit	2023-09-05
7464	441	155.20	withdrawal	2024-04-15
7465	711	102.20	deposit	2023-02-08
7466	206	336.70	withdrawal	2023-09-06
7467	1226	316.20	deposit	2023-05-12
7468	255	333.80	withdrawal	2023-07-03
7469	1524	405.00	withdrawal	2023-12-30
7470	1001	152.20	withdrawal	2024-01-17
7471	1435	355.50	deposit	2023-08-14
7472	238	30.90	deposit	2023-05-16
7473	985	91.70	deposit	2023-01-31
7474	1037	241.10	deposit	2023-11-06
7475	1452	262.10	withdrawal	2023-05-23
7476	1760	449.70	withdrawal	2023-05-25
7477	1558	333.20	deposit	2023-09-12
7478	1537	147.60	withdrawal	2024-04-15
7479	210	181.00	withdrawal	2023-03-01
7480	1356	62.50	withdrawal	2023-10-10
7481	1495	113.30	withdrawal	2023-05-02
7482	908	287.40	deposit	2023-08-08
7483	1345	499.80	deposit	2023-11-09
7484	1684	444.40	withdrawal	2024-01-11
7485	876	52.20	withdrawal	2023-07-23
7486	772	352.30	deposit	2024-04-13
7487	711	461.10	withdrawal	2024-04-09
7488	1140	367.50	deposit	2024-01-23
7489	1621	28.60	deposit	2023-06-26
7490	1254	76.00	deposit	2023-03-23
7491	860	312.10	deposit	2023-08-18
7492	144	128.00	withdrawal	2024-03-04
7493	811	11.30	withdrawal	2023-02-08
7494	1051	286.00	withdrawal	2023-09-14
7495	1690	384.20	deposit	2023-01-24
7496	1725	8.60	deposit	2023-12-31
7497	1422	123.20	withdrawal	2024-04-24
7498	1042	438.20	withdrawal	2024-01-12
7499	15	322.90	withdrawal	2024-03-31
7500	262	209.60	withdrawal	2023-10-07
7501	1706	77.50	withdrawal	2024-04-10
7502	503	280.80	deposit	2024-01-11
7503	1739	74.80	withdrawal	2023-05-30
7504	459	69.50	deposit	2023-08-31
7505	1371	216.70	withdrawal	2023-03-02
7506	939	225.60	deposit	2023-01-09
7507	1695	124.20	withdrawal	2023-12-12
7508	545	100.30	withdrawal	2024-03-21
7509	1477	324.60	withdrawal	2023-02-25
7510	99	337.60	withdrawal	2023-12-15
7511	727	332.70	deposit	2023-02-09
7512	1784	152.80	deposit	2024-02-16
7513	400	81.10	withdrawal	2023-03-17
7514	901	375.80	withdrawal	2023-04-12
7515	156	233.10	deposit	2024-03-30
7516	538	134.10	withdrawal	2023-08-03
7517	187	49.60	deposit	2023-03-04
7518	1666	235.60	deposit	2023-03-16
7519	1079	316.80	deposit	2023-05-29
7520	411	477.10	withdrawal	2024-01-05
7521	133	21.10	deposit	2023-05-26
7522	68	298.60	withdrawal	2024-02-14
7523	475	226.10	deposit	2024-03-30
7524	1482	332.10	withdrawal	2023-10-27
7525	836	106.20	deposit	2023-09-03
7526	1752	332.60	withdrawal	2023-03-23
7527	677	254.10	withdrawal	2023-11-20
7528	312	309.70	withdrawal	2024-04-19
7529	973	58.10	withdrawal	2023-12-22
7530	560	348.20	deposit	2023-01-29
7531	8	420.50	deposit	2023-08-23
7532	113	262.40	deposit	2023-12-28
7533	1549	170.70	deposit	2024-03-22
7534	1692	352.90	withdrawal	2024-03-01
7535	1008	382.60	deposit	2024-03-24
7536	1776	379.00	deposit	2023-12-20
7537	1509	103.40	withdrawal	2023-07-12
7538	560	110.30	deposit	2024-05-06
7539	1664	92.80	withdrawal	2024-03-25
7540	1585	352.20	deposit	2024-03-30
7541	1068	444.40	deposit	2023-05-16
7542	1774	125.50	deposit	2023-02-02
7543	1092	426.80	deposit	2023-01-27
7544	1289	352.60	withdrawal	2024-02-12
7545	835	423.80	withdrawal	2023-03-08
7546	1774	430.90	deposit	2023-12-30
7547	221	161.10	deposit	2023-01-28
7548	560	257.10	withdrawal	2023-12-14
7549	1602	383.40	withdrawal	2023-08-27
7550	1218	461.60	deposit	2023-10-01
7551	1242	134.90	withdrawal	2024-04-11
7552	824	101.60	deposit	2023-04-29
7553	350	111.80	withdrawal	2023-07-25
7554	525	392.70	deposit	2024-03-16
7555	450	113.30	deposit	2024-03-08
7556	265	376.50	deposit	2023-02-09
7557	1167	267.60	withdrawal	2024-04-26
7558	110	239.40	deposit	2023-08-05
7559	1182	430.50	deposit	2023-09-17
7560	54	378.10	withdrawal	2023-10-19
7561	1703	365.90	deposit	2023-08-28
7562	522	248.60	withdrawal	2024-05-11
7563	1158	315.20	withdrawal	2023-07-08
7564	1066	16.60	deposit	2023-03-11
7565	1	416.40	deposit	2023-01-04
7566	67	325.90	deposit	2023-02-22
7567	463	218.70	deposit	2023-01-23
7568	1578	410.30	deposit	2023-06-13
7569	715	57.70	withdrawal	2023-03-19
7570	1708	354.40	deposit	2024-01-29
7571	163	179.60	withdrawal	2023-09-24
7572	1511	328.70	deposit	2023-09-14
7573	853	30.60	withdrawal	2024-04-19
7574	189	277.60	withdrawal	2024-05-29
7575	1587	373.60	withdrawal	2023-04-27
7576	1140	187.70	withdrawal	2023-08-19
7577	1463	223.90	withdrawal	2023-11-03
7578	283	377.10	withdrawal	2023-06-02
7579	330	390.00	deposit	2023-03-09
7580	971	470.90	withdrawal	2023-03-04
7581	647	247.80	deposit	2023-08-13
7582	1150	66.90	withdrawal	2024-01-31
7583	1715	415.60	deposit	2023-04-27
7584	603	484.70	deposit	2024-02-20
7585	1055	81.60	withdrawal	2024-01-13
7586	1278	485.60	deposit	2024-05-10
7587	1217	383.70	withdrawal	2023-11-28
7588	955	493.90	deposit	2023-04-11
7589	883	308.40	withdrawal	2024-04-17
7590	670	311.40	withdrawal	2023-03-04
7591	94	438.00	deposit	2024-05-16
7592	737	292.80	deposit	2023-07-09
7593	666	157.60	withdrawal	2024-03-08
7594	1788	350.00	deposit	2023-07-12
7595	1393	315.40	withdrawal	2024-02-29
7596	291	244.20	withdrawal	2024-02-11
7597	761	335.60	withdrawal	2023-08-28
7598	1444	363.70	withdrawal	2023-08-12
7599	776	41.70	deposit	2023-04-23
7600	652	263.10	withdrawal	2023-05-22
7601	551	363.00	withdrawal	2023-06-24
7602	1110	414.50	withdrawal	2023-04-11
7603	1290	12.50	deposit	2024-04-05
7604	1038	331.30	deposit	2023-10-22
7605	1761	463.10	deposit	2023-08-25
7606	756	273.30	withdrawal	2023-07-10
7607	11	240.90	withdrawal	2024-03-31
7608	512	364.20	deposit	2023-10-11
7609	1688	70.70	withdrawal	2024-05-25
7610	1223	169.80	withdrawal	2023-09-30
7611	412	63.40	withdrawal	2023-07-16
7612	1656	490.70	withdrawal	2024-02-12
7613	1270	130.40	deposit	2024-01-21
7614	1126	266.00	withdrawal	2023-01-23
7615	604	447.10	withdrawal	2024-03-29
7616	73	229.30	withdrawal	2023-01-03
7617	1011	157.20	deposit	2023-06-25
7618	729	439.70	deposit	2023-08-11
7619	1679	159.00	withdrawal	2024-05-27
7620	602	147.60	withdrawal	2023-08-12
7621	1124	187.70	deposit	2023-12-09
7622	779	161.90	withdrawal	2023-09-25
7623	1382	472.20	withdrawal	2024-05-21
7624	135	449.70	deposit	2024-04-24
7625	1488	473.00	withdrawal	2023-05-05
7626	593	363.80	deposit	2023-08-10
7627	938	417.80	withdrawal	2023-01-30
7628	300	128.60	deposit	2023-08-31
7629	1057	57.50	withdrawal	2023-09-23
7630	631	143.30	withdrawal	2023-03-12
7631	693	269.40	withdrawal	2024-03-16
7632	1286	279.90	deposit	2023-04-11
7633	1222	382.40	withdrawal	2023-02-11
7634	1443	251.70	deposit	2024-05-15
7635	1728	313.10	deposit	2023-01-07
7636	672	118.30	deposit	2023-03-04
7637	377	69.00	withdrawal	2024-01-13
7638	676	361.70	withdrawal	2023-10-02
7639	1694	303.00	deposit	2023-04-15
7640	111	14.70	withdrawal	2023-03-25
7641	1788	146.40	withdrawal	2023-05-03
7642	1688	309.90	deposit	2023-08-04
7643	1735	182.30	deposit	2023-06-09
7644	494	63.70	deposit	2023-03-15
7645	196	286.80	withdrawal	2024-02-19
7646	150	65.10	deposit	2023-10-30
7647	1679	52.90	withdrawal	2023-05-29
7648	276	195.80	withdrawal	2023-10-01
7649	1529	196.40	withdrawal	2023-02-21
7650	53	296.00	withdrawal	2024-03-27
7651	11	103.20	withdrawal	2023-04-01
7652	1409	351.30	withdrawal	2024-03-29
7653	59	176.40	withdrawal	2023-06-23
7654	1690	245.50	withdrawal	2024-03-10
7655	40	255.30	withdrawal	2024-04-18
7656	210	14.40	deposit	2024-02-19
7657	692	375.40	withdrawal	2024-05-24
7658	1065	234.60	deposit	2024-01-21
7659	569	279.50	withdrawal	2023-03-10
7660	1660	493.80	deposit	2024-05-04
7661	681	273.10	withdrawal	2023-08-18
7662	436	488.80	withdrawal	2023-08-25
7663	853	189.60	withdrawal	2023-11-05
7664	596	133.80	withdrawal	2024-04-04
7665	1739	254.50	withdrawal	2023-05-26
7666	1509	224.80	deposit	2023-02-04
7667	642	62.90	deposit	2023-04-01
7668	497	440.70	deposit	2024-01-28
7669	1351	11.70	withdrawal	2024-04-01
7670	225	446.50	withdrawal	2023-07-30
7671	1616	158.40	withdrawal	2023-04-25
7672	360	8.30	deposit	2023-09-05
7673	1282	10.20	withdrawal	2024-01-08
7674	325	496.40	deposit	2024-01-20
7675	835	484.90	deposit	2023-01-30
7676	2	31.90	deposit	2024-05-18
7677	757	210.50	deposit	2024-02-10
7678	1617	331.50	withdrawal	2023-06-02
7679	954	428.80	deposit	2024-02-09
7680	1684	257.50	deposit	2023-07-15
7681	561	485.70	withdrawal	2023-04-29
7682	22	369.50	deposit	2023-03-04
7683	939	222.60	withdrawal	2023-03-11
7684	1112	431.50	withdrawal	2023-02-04
7685	202	17.00	deposit	2023-10-03
7686	1528	305.10	deposit	2024-02-28
7687	1246	272.90	deposit	2023-03-10
7688	175	271.70	deposit	2023-07-17
7689	938	357.70	withdrawal	2023-12-30
7690	281	93.90	deposit	2023-05-24
7691	79	436.90	withdrawal	2023-12-27
7692	1768	185.00	deposit	2023-11-29
7693	1070	342.30	withdrawal	2024-01-11
7694	1595	224.50	withdrawal	2023-03-18
7695	411	183.10	deposit	2024-05-23
7696	1447	143.00	deposit	2023-06-11
7697	1024	361.90	withdrawal	2023-05-21
7698	707	82.80	withdrawal	2023-03-21
7699	1221	362.60	deposit	2023-12-24
7700	159	48.90	withdrawal	2023-01-05
7701	1102	101.90	deposit	2023-11-05
7702	379	100.40	withdrawal	2024-05-01
7703	331	151.80	deposit	2024-05-26
7704	202	294.80	withdrawal	2023-05-11
7705	1447	472.60	withdrawal	2024-02-06
7706	1100	355.90	withdrawal	2023-02-08
7707	932	140.90	withdrawal	2023-11-08
7708	210	131.40	deposit	2023-11-23
7709	869	379.10	withdrawal	2023-11-08
7710	154	412.90	withdrawal	2024-04-05
7711	155	256.50	withdrawal	2023-12-07
7712	869	463.10	deposit	2024-02-05
7713	1380	418.20	deposit	2023-06-20
7714	165	386.10	deposit	2023-01-29
7715	609	349.30	deposit	2023-05-28
7716	486	197.20	deposit	2023-12-12
7717	1758	363.90	withdrawal	2023-04-24
7718	578	29.00	deposit	2024-03-18
7719	1111	95.20	withdrawal	2023-02-04
7720	1776	352.00	withdrawal	2024-01-05
7721	1716	164.50	deposit	2024-02-17
7722	1441	355.70	deposit	2023-07-17
7723	536	484.60	deposit	2023-05-17
7724	1698	463.30	withdrawal	2023-10-19
7725	927	321.80	deposit	2023-09-12
7726	1316	428.80	withdrawal	2023-11-18
7727	1459	431.50	withdrawal	2024-04-20
7728	281	229.50	withdrawal	2024-04-12
7729	1599	271.00	withdrawal	2023-05-21
7730	1610	351.20	withdrawal	2023-11-12
7731	800	180.70	deposit	2024-04-21
7732	372	258.30	withdrawal	2023-03-01
7733	923	379.20	deposit	2024-02-17
7734	538	361.40	withdrawal	2023-04-12
7735	1391	173.40	deposit	2023-04-28
7736	439	496.10	deposit	2023-01-24
7737	1563	425.60	withdrawal	2023-09-02
7738	1737	158.90	deposit	2024-03-13
7739	1464	221.50	deposit	2024-02-20
7740	459	253.20	deposit	2023-05-23
7741	263	220.70	withdrawal	2023-03-31
7742	581	474.90	deposit	2023-08-03
7743	733	202.40	deposit	2023-03-28
7744	1418	185.00	deposit	2023-04-15
7745	19	58.50	withdrawal	2023-01-01
7746	1554	90.30	deposit	2023-01-09
7747	1190	174.90	withdrawal	2023-04-11
7748	517	84.00	deposit	2023-08-08
7749	1169	7.40	deposit	2023-06-10
7750	1558	316.50	deposit	2023-07-16
7751	1453	130.40	withdrawal	2024-05-26
7752	146	326.00	deposit	2024-05-30
7753	342	38.90	deposit	2023-11-15
7754	618	132.10	deposit	2024-02-13
7755	602	415.20	withdrawal	2023-07-27
7756	538	190.10	withdrawal	2024-04-29
7757	64	469.60	deposit	2023-07-20
7758	211	448.60	withdrawal	2024-04-20
7759	1075	416.30	deposit	2023-06-20
7760	1074	251.30	withdrawal	2023-11-29
7761	676	285.20	deposit	2024-01-08
7762	70	481.60	withdrawal	2023-10-14
7763	76	266.10	deposit	2023-06-02
7764	1028	84.20	withdrawal	2024-05-28
7765	879	497.50	withdrawal	2023-10-27
7766	940	45.50	withdrawal	2023-09-30
7767	73	267.80	deposit	2023-02-15
7768	38	377.40	withdrawal	2023-07-15
7769	1454	207.50	deposit	2023-05-10
7770	1469	399.80	deposit	2024-04-05
7771	1508	243.60	deposit	2023-08-16
7772	1020	278.60	deposit	2023-04-08
7773	450	377.90	withdrawal	2024-03-09
7774	300	337.10	deposit	2023-05-22
7775	1232	213.80	withdrawal	2024-05-17
7776	223	187.80	deposit	2024-03-11
7777	1252	193.50	withdrawal	2023-08-19
7778	916	425.30	withdrawal	2023-11-27
7779	406	71.80	deposit	2024-02-05
7780	1123	432.70	deposit	2023-12-31
7781	679	20.20	withdrawal	2023-04-11
7782	1704	350.50	withdrawal	2024-04-19
7783	13	153.20	withdrawal	2024-01-28
7784	1609	241.00	withdrawal	2023-07-20
7785	731	436.80	deposit	2023-08-18
7786	1767	458.80	deposit	2023-11-03
7787	1087	129.10	withdrawal	2024-03-20
7788	1744	230.00	deposit	2023-01-28
7789	56	339.80	deposit	2023-12-03
7790	1783	100.20	deposit	2023-05-27
7791	1	439.60	deposit	2023-01-19
7792	1743	440.60	deposit	2024-05-26
7793	375	357.80	deposit	2024-04-06
7794	695	74.30	withdrawal	2023-10-03
7795	1604	404.30	withdrawal	2023-12-08
7796	133	373.60	deposit	2024-02-23
7797	1223	316.10	deposit	2023-03-23
7798	1129	169.10	withdrawal	2024-05-18
7799	1100	302.10	withdrawal	2023-09-18
7800	987	17.40	withdrawal	2023-11-02
7801	71	108.10	deposit	2023-09-02
7802	309	43.00	deposit	2023-06-04
7803	443	150.20	deposit	2023-05-16
7804	631	388.30	withdrawal	2024-04-30
7805	1357	101.10	withdrawal	2023-04-05
7806	1761	411.80	withdrawal	2023-07-03
7807	1247	471.70	deposit	2023-10-21
7808	161	93.00	withdrawal	2023-05-29
7809	73	148.00	deposit	2024-04-15
7810	829	276.30	deposit	2023-06-25
7811	861	207.90	deposit	2024-04-07
7812	659	74.90	withdrawal	2023-08-18
7813	1517	260.50	withdrawal	2023-03-02
7814	756	137.60	deposit	2024-02-20
7815	1131	135.40	withdrawal	2023-06-21
7816	16	132.10	withdrawal	2023-10-14
7817	1231	327.80	withdrawal	2023-04-04
7818	1424	27.50	deposit	2024-05-11
7819	399	135.40	withdrawal	2023-05-31
7820	281	103.20	withdrawal	2023-11-04
7821	823	269.10	withdrawal	2023-10-07
7822	1491	442.50	deposit	2023-09-13
7823	430	177.50	withdrawal	2023-06-05
7824	1693	450.60	deposit	2023-08-20
7825	222	111.30	deposit	2023-11-16
7826	450	101.10	deposit	2024-05-26
7827	418	208.10	deposit	2023-12-31
7828	1395	452.10	withdrawal	2023-11-30
7829	814	130.70	deposit	2023-05-13
7830	1776	24.30	withdrawal	2023-07-04
7831	335	56.60	withdrawal	2023-12-03
7832	1388	19.30	deposit	2023-08-29
7833	1018	299.70	deposit	2023-09-09
7834	631	261.20	withdrawal	2024-02-02
7835	1606	45.20	deposit	2024-05-31
7836	577	202.60	withdrawal	2023-03-14
7837	359	41.50	withdrawal	2023-08-27
7838	716	283.20	deposit	2024-01-21
7839	1540	302.60	withdrawal	2024-01-09
7840	748	214.60	withdrawal	2024-01-13
7841	1049	221.60	deposit	2023-09-24
7842	1172	483.90	deposit	2024-02-07
7843	1408	317.80	withdrawal	2023-11-23
7844	1728	478.70	deposit	2023-03-04
7845	661	202.30	deposit	2023-06-22
7846	207	115.80	deposit	2023-01-29
7847	162	441.20	deposit	2023-09-21
7848	1315	344.90	withdrawal	2023-01-26
7849	1444	356.50	deposit	2023-11-17
7850	1454	207.00	deposit	2024-05-12
7851	1495	149.50	withdrawal	2023-02-01
7852	28	478.70	deposit	2023-12-31
7853	855	376.30	withdrawal	2023-04-17
7854	1341	316.90	deposit	2023-08-25
7855	738	97.60	deposit	2023-06-03
7856	1146	360.40	withdrawal	2023-09-01
7857	1237	52.50	deposit	2023-09-11
7858	4	475.60	deposit	2023-05-14
7859	243	128.30	deposit	2024-01-07
7860	666	273.80	withdrawal	2023-08-20
7861	1552	469.30	withdrawal	2023-01-24
7862	349	64.10	deposit	2024-03-08
7863	1425	326.00	deposit	2024-04-11
7864	658	15.30	deposit	2024-01-02
7865	125	298.70	deposit	2023-09-12
7866	132	49.40	deposit	2023-06-20
7867	1237	394.90	withdrawal	2023-12-10
7868	1265	436.60	withdrawal	2023-09-09
7869	1477	470.10	withdrawal	2024-05-02
7870	1495	372.90	deposit	2023-12-16
7871	1609	408.70	deposit	2023-11-18
7872	1289	380.60	deposit	2024-01-26
7873	1607	210.60	deposit	2024-03-29
7874	1224	328.60	withdrawal	2024-03-23
7875	420	385.70	deposit	2024-04-17
7876	1765	212.90	withdrawal	2023-09-07
7877	1680	196.70	withdrawal	2023-02-27
7878	153	141.70	withdrawal	2024-04-08
7879	352	381.30	deposit	2023-09-19
7880	857	118.00	deposit	2023-02-11
7881	1584	240.70	deposit	2023-10-21
7882	1354	430.60	deposit	2023-03-12
7883	1652	441.00	withdrawal	2023-12-26
7884	1572	394.90	withdrawal	2024-04-01
7885	1517	300.10	withdrawal	2024-03-09
7886	1169	91.20	deposit	2023-08-07
7887	91	113.20	deposit	2024-03-23
7888	1136	362.00	deposit	2024-02-04
7889	1218	190.60	deposit	2024-02-23
7890	977	64.80	deposit	2024-01-29
7891	501	265.20	withdrawal	2023-02-01
7892	1410	234.70	deposit	2023-12-18
7893	263	29.20	deposit	2023-02-11
7894	454	437.10	withdrawal	2024-04-22
7895	249	222.50	withdrawal	2023-12-08
7896	198	397.00	deposit	2023-05-16
7897	329	213.90	deposit	2023-03-11
7898	792	428.70	deposit	2023-04-07
7899	937	40.90	deposit	2023-06-01
7900	127	115.20	deposit	2023-05-20
7901	754	421.60	withdrawal	2023-09-16
7902	413	492.30	withdrawal	2023-06-06
7903	668	287.70	deposit	2024-04-13
7904	934	12.40	deposit	2023-11-22
7905	929	40.90	deposit	2023-07-21
7906	351	187.20	deposit	2024-05-11
7907	1191	394.70	deposit	2023-09-25
7908	41	282.80	deposit	2023-06-23
7909	942	283.30	deposit	2024-03-10
7910	464	354.80	deposit	2023-10-05
7911	281	93.70	deposit	2024-01-28
7912	1623	196.90	deposit	2024-05-31
7913	855	113.20	deposit	2023-05-22
7914	221	144.20	withdrawal	2024-04-30
7915	997	380.20	withdrawal	2023-11-08
7916	575	312.30	withdrawal	2023-03-04
7917	355	64.90	deposit	2023-10-06
7918	378	389.20	deposit	2024-04-11
7919	1312	82.40	withdrawal	2023-02-09
7920	228	240.50	deposit	2023-01-21
7921	948	365.30	deposit	2023-03-04
7922	1617	250.00	deposit	2024-04-29
7923	357	169.70	withdrawal	2023-04-29
7924	546	395.00	withdrawal	2023-03-23
7925	411	60.60	withdrawal	2023-05-24
7926	181	204.50	deposit	2024-02-15
7927	1566	416.70	deposit	2024-03-30
7928	1504	484.10	withdrawal	2024-01-13
7929	125	267.80	withdrawal	2023-05-05
7930	1392	146.70	deposit	2023-01-30
7931	1291	18.40	deposit	2024-04-17
7932	79	307.70	deposit	2023-07-16
7933	1650	492.70	withdrawal	2024-05-07
7934	7	190.80	withdrawal	2024-03-27
7935	608	441.90	deposit	2023-01-21
7936	741	250.80	withdrawal	2023-10-26
7937	1608	110.10	deposit	2024-03-20
7938	1001	126.20	deposit	2023-10-03
7939	356	485.40	withdrawal	2023-03-02
7940	385	435.40	withdrawal	2024-03-12
7941	674	15.00	withdrawal	2024-02-22
7942	93	496.30	deposit	2023-09-20
7943	1511	230.00	withdrawal	2024-04-27
7944	1625	426.20	withdrawal	2023-10-15
7945	902	281.10	deposit	2023-10-04
7946	1155	88.60	withdrawal	2023-02-28
7947	1256	64.80	deposit	2023-03-29
7948	1133	103.30	withdrawal	2024-03-27
7949	1491	19.00	deposit	2023-02-25
7950	780	16.40	deposit	2024-01-28
7951	1041	246.60	withdrawal	2023-03-07
7952	950	301.20	deposit	2024-02-24
7953	555	340.30	deposit	2023-01-25
7954	580	351.90	deposit	2023-08-13
7955	790	192.80	withdrawal	2024-03-14
7956	423	312.70	withdrawal	2023-11-19
7957	422	486.30	withdrawal	2024-01-06
7958	193	326.90	deposit	2024-05-26
7959	1265	104.60	withdrawal	2023-09-07
7960	430	47.10	withdrawal	2024-05-08
7961	904	265.60	withdrawal	2023-12-31
7962	1227	160.50	deposit	2024-01-02
7963	1454	169.80	withdrawal	2023-06-03
7964	1283	430.70	withdrawal	2024-01-09
7965	1785	330.30	deposit	2023-08-29
7966	635	8.50	withdrawal	2023-02-08
7967	1024	447.60	withdrawal	2023-05-03
7968	914	310.00	withdrawal	2024-01-06
7969	1354	421.60	withdrawal	2024-05-02
7970	172	83.40	deposit	2023-10-09
7971	1153	107.10	deposit	2023-11-27
7972	1206	293.80	deposit	2024-04-10
7973	747	35.20	deposit	2024-05-21
7974	696	40.20	deposit	2023-08-09
7975	1405	143.90	withdrawal	2023-11-21
7976	331	365.20	withdrawal	2023-10-10
7977	12	127.90	withdrawal	2024-02-11
7978	98	160.40	withdrawal	2023-12-08
7979	500	408.90	deposit	2023-10-19
7980	895	73.10	withdrawal	2024-01-15
7981	1412	468.70	withdrawal	2023-10-05
7982	1547	89.90	deposit	2023-12-08
7983	1460	152.60	deposit	2023-05-16
7984	806	400.90	deposit	2023-05-20
7985	1519	69.50	withdrawal	2023-12-01
7986	643	325.20	withdrawal	2024-02-29
7987	1719	194.90	deposit	2023-12-04
7988	387	491.10	deposit	2023-11-11
7989	1457	494.20	withdrawal	2023-10-24
7990	1343	87.50	deposit	2024-05-01
7991	614	19.40	deposit	2023-07-26
7992	694	364.80	withdrawal	2023-09-14
7993	767	224.80	withdrawal	2023-10-14
7994	1575	264.70	deposit	2024-03-04
7995	774	381.00	withdrawal	2023-07-09
7996	517	292.90	deposit	2023-01-18
7997	1284	54.80	deposit	2023-10-03
7998	1447	37.00	withdrawal	2023-04-06
7999	1112	129.90	deposit	2023-08-29
8000	325	416.20	withdrawal	2023-07-04
8001	115	36.00	deposit	2023-01-21
8002	209	105.90	withdrawal	2023-02-05
8003	25	100.00	deposit	2023-12-03
8004	19	218.30	withdrawal	2023-05-26
8005	344	373.60	withdrawal	2024-05-06
8006	605	315.20	deposit	2023-02-01
8007	715	54.50	deposit	2024-04-14
8008	274	62.50	withdrawal	2024-01-14
8009	926	251.80	deposit	2023-08-01
8010	379	136.50	withdrawal	2024-05-24
8011	840	296.10	withdrawal	2023-04-29
8012	1665	459.50	withdrawal	2023-08-10
8013	647	154.00	withdrawal	2024-04-25
8014	856	412.20	deposit	2023-01-05
8015	210	306.30	deposit	2023-10-02
8016	828	151.10	deposit	2024-03-29
8017	744	284.20	deposit	2023-04-11
8018	249	407.40	withdrawal	2024-03-04
8019	284	235.70	deposit	2024-02-19
8020	1622	57.60	deposit	2023-11-23
8021	1785	215.10	deposit	2023-09-13
8022	1491	72.60	withdrawal	2023-05-05
8023	327	340.80	deposit	2023-02-23
8024	1461	124.00	deposit	2023-04-22
8025	1205	465.20	withdrawal	2023-10-21
8026	1170	420.70	deposit	2023-10-01
8027	153	340.20	deposit	2024-04-14
8028	880	207.50	deposit	2024-02-26
8029	584	116.60	deposit	2024-02-11
8030	1523	100.90	withdrawal	2023-08-13
8031	362	134.40	withdrawal	2023-06-02
8032	1730	402.10	deposit	2023-11-17
8033	476	158.90	withdrawal	2023-05-17
8034	35	402.60	withdrawal	2023-09-18
8035	1344	56.50	withdrawal	2024-05-17
8036	764	101.20	deposit	2023-08-23
8037	682	153.50	withdrawal	2023-02-14
8038	562	32.30	withdrawal	2023-12-17
8039	1262	133.60	withdrawal	2023-11-25
8040	475	491.70	deposit	2023-04-15
8041	871	214.20	withdrawal	2023-05-13
8042	269	358.10	deposit	2024-04-05
8043	149	365.70	withdrawal	2023-12-04
8044	1422	114.20	withdrawal	2023-12-06
8045	1648	370.30	deposit	2023-08-13
8046	142	185.40	deposit	2023-01-13
8047	1178	171.00	deposit	2024-03-02
8048	433	116.80	deposit	2024-03-18
8049	376	372.10	withdrawal	2023-07-19
8050	459	344.10	deposit	2024-05-26
8051	516	100.40	withdrawal	2023-12-10
8052	1586	471.80	deposit	2023-07-27
8053	266	338.10	deposit	2024-03-24
8054	581	354.90	withdrawal	2023-06-03
8055	1322	463.20	deposit	2024-01-03
8056	1740	44.20	withdrawal	2023-07-06
8057	565	235.80	withdrawal	2023-08-15
8058	824	71.60	withdrawal	2023-07-24
8059	1287	15.50	deposit	2024-02-21
8060	236	49.10	deposit	2023-08-31
8061	181	355.50	withdrawal	2024-05-09
8062	969	450.60	deposit	2024-03-26
8063	443	430.40	deposit	2023-10-11
8064	660	297.30	deposit	2023-02-25
8065	1600	465.40	withdrawal	2023-07-10
8066	1	217.60	withdrawal	2024-06-07
8067	1658	97.40	withdrawal	2024-05-04
8068	399	22.10	withdrawal	2023-04-21
8069	943	462.10	withdrawal	2023-08-17
8070	497	482.80	deposit	2023-04-01
8071	1548	415.40	withdrawal	2024-04-07
8072	1255	312.60	withdrawal	2024-01-02
8073	259	247.40	deposit	2024-05-14
8074	1238	167.80	withdrawal	2024-03-18
8075	1605	457.40	withdrawal	2023-06-20
8076	853	415.80	deposit	2024-03-03
8077	1208	294.80	deposit	2023-05-03
8078	708	407.80	withdrawal	2023-01-05
8079	346	96.20	withdrawal	2023-03-04
8080	490	306.40	deposit	2023-09-26
8081	80	430.90	deposit	2024-04-02
8082	616	147.90	withdrawal	2023-02-27
8083	536	127.10	withdrawal	2024-05-04
8084	1766	78.00	withdrawal	2023-05-18
8085	877	306.20	withdrawal	2024-02-13
8086	1209	358.40	withdrawal	2024-03-13
8087	820	64.50	deposit	2023-12-20
8088	297	200.90	deposit	2023-02-24
8089	812	384.60	withdrawal	2024-01-12
8090	1098	21.50	withdrawal	2024-03-26
8091	934	55.40	deposit	2024-01-27
8092	1782	134.00	withdrawal	2023-05-10
8093	1192	383.90	withdrawal	2023-11-13
8094	365	74.50	deposit	2024-01-26
8095	515	196.10	deposit	2023-04-30
8096	887	467.80	deposit	2024-04-21
8097	1167	302.90	withdrawal	2023-05-16
8098	1308	272.30	withdrawal	2023-03-06
8099	1342	402.80	deposit	2024-01-24
8100	1617	237.40	withdrawal	2023-12-16
8101	1371	41.10	deposit	2023-02-18
8102	1227	6.40	deposit	2024-04-04
8103	780	499.20	withdrawal	2024-05-18
8104	94	226.50	deposit	2024-01-13
8105	513	28.70	deposit	2023-05-24
8106	1578	98.80	withdrawal	2023-02-19
8107	285	85.30	withdrawal	2024-01-17
8108	1718	422.30	deposit	2023-04-30
8109	540	215.50	withdrawal	2023-10-06
8110	655	202.50	deposit	2024-04-08
8111	1438	227.80	withdrawal	2024-05-22
8112	366	330.60	deposit	2023-01-30
8113	656	324.40	withdrawal	2024-05-30
8114	1587	372.50	withdrawal	2023-10-18
8115	1539	33.50	withdrawal	2024-03-25
8116	414	48.70	deposit	2023-01-07
8117	740	243.70	deposit	2023-05-27
8118	1724	22.90	withdrawal	2023-03-08
8119	424	498.70	withdrawal	2023-07-20
8120	1563	255.40	deposit	2024-01-20
8121	1626	382.60	deposit	2024-04-25
8122	305	490.00	deposit	2023-11-10
8123	20	434.70	withdrawal	2023-08-25
8124	209	321.30	withdrawal	2023-07-28
8125	975	176.30	deposit	2023-03-31
8126	509	278.40	deposit	2023-06-21
8127	1783	394.30	deposit	2023-08-31
8128	1538	25.50	deposit	2024-04-18
8129	1075	275.30	deposit	2023-06-27
8130	1086	168.60	withdrawal	2024-03-23
8131	339	320.70	withdrawal	2023-05-04
8132	63	271.50	deposit	2023-02-07
8133	532	298.00	deposit	2024-02-08
8134	34	259.20	withdrawal	2023-06-20
8135	1128	136.60	withdrawal	2024-02-24
8136	386	425.80	deposit	2023-10-19
8137	1162	378.80	deposit	2024-05-27
8138	817	360.40	withdrawal	2023-09-28
8139	152	179.90	withdrawal	2023-09-28
8140	473	191.00	withdrawal	2023-08-27
8141	763	305.20	withdrawal	2023-07-05
8142	1437	210.70	deposit	2023-11-07
8143	926	300.20	deposit	2024-01-20
8144	1654	393.80	withdrawal	2023-02-02
8145	789	162.50	deposit	2023-02-19
8146	240	262.50	withdrawal	2023-03-25
8147	1746	367.40	withdrawal	2024-03-22
8148	633	149.00	withdrawal	2024-05-10
8149	1704	21.60	withdrawal	2024-03-22
8150	125	92.70	withdrawal	2023-02-18
8151	1132	169.40	withdrawal	2023-04-20
8152	288	386.80	deposit	2023-01-01
8153	866	195.00	deposit	2024-03-18
8154	447	316.50	withdrawal	2024-05-12
8155	880	433.90	withdrawal	2024-01-02
8156	1649	474.40	deposit	2023-02-21
8157	1646	481.90	deposit	2024-04-18
8158	765	275.80	withdrawal	2023-08-16
8159	1217	256.70	withdrawal	2023-11-10
8160	1105	301.90	withdrawal	2023-07-25
8161	1567	461.50	deposit	2023-11-20
8162	1546	262.90	deposit	2023-12-09
8163	169	75.50	withdrawal	2023-11-26
8164	76	460.00	deposit	2023-02-22
8165	369	313.80	deposit	2023-01-05
8166	1244	280.40	deposit	2023-05-08
8167	12	367.50	deposit	2024-03-30
8168	1333	277.50	withdrawal	2023-04-08
8169	544	12.00	deposit	2023-01-19
8170	643	294.50	deposit	2023-04-04
8171	1219	413.50	withdrawal	2023-01-18
8172	655	390.60	withdrawal	2023-05-12
8173	78	60.10	deposit	2023-08-02
8174	1187	332.40	withdrawal	2023-04-11
8175	393	224.40	withdrawal	2023-04-29
8176	790	215.10	deposit	2023-01-26
8177	1480	115.40	deposit	2024-02-18
8178	468	47.80	deposit	2024-04-19
8179	1576	12.20	deposit	2023-11-27
8180	443	133.10	deposit	2023-10-17
8181	1682	406.20	deposit	2024-05-08
8182	783	376.40	withdrawal	2023-09-02
8183	1125	95.70	deposit	2024-01-26
8184	823	422.60	deposit	2023-10-12
8185	1158	331.80	withdrawal	2024-04-18
8186	38	412.00	withdrawal	2024-03-06
8187	741	163.90	withdrawal	2023-11-12
8188	193	34.90	withdrawal	2024-04-06
8189	1180	160.00	withdrawal	2024-03-09
8190	290	486.00	deposit	2024-01-29
8191	1077	91.80	deposit	2023-05-15
8192	588	165.80	deposit	2023-09-22
8193	1553	269.70	withdrawal	2023-04-02
8194	1008	16.70	withdrawal	2023-08-01
8195	1306	454.60	withdrawal	2023-03-31
8196	295	184.00	withdrawal	2023-07-21
8197	1027	474.60	deposit	2023-02-15
8198	1276	185.00	withdrawal	2023-05-19
8199	1579	393.70	withdrawal	2023-07-27
8200	979	461.80	withdrawal	2023-01-01
8201	1376	325.00	deposit	2023-05-21
8202	1649	252.20	withdrawal	2023-10-11
8203	768	81.40	withdrawal	2023-11-19
8204	1677	200.00	deposit	2023-01-28
8205	1494	16.00	deposit	2023-03-28
8206	568	285.60	deposit	2023-03-27
8207	1427	326.40	withdrawal	2023-10-28
8208	1463	335.90	withdrawal	2024-03-22
8209	379	463.00	deposit	2023-10-13
8210	504	44.30	deposit	2023-04-01
8211	351	377.20	withdrawal	2023-02-06
8212	542	218.30	deposit	2024-03-21
8213	297	244.40	withdrawal	2023-05-13
8214	1111	262.20	withdrawal	2023-10-18
8215	1353	255.80	deposit	2023-09-18
8216	774	391.50	withdrawal	2023-07-02
8217	1611	260.80	deposit	2023-09-28
8218	1189	170.80	withdrawal	2023-12-31
8219	455	163.60	withdrawal	2023-06-18
8220	67	166.10	deposit	2023-04-20
8221	814	344.40	withdrawal	2023-01-25
8222	376	84.20	deposit	2023-03-25
8223	923	478.40	withdrawal	2023-01-08
8224	793	147.00	deposit	2023-08-04
8225	1308	143.20	deposit	2024-04-05
8226	1652	14.60	deposit	2023-05-06
8227	523	357.90	deposit	2024-05-12
8228	1185	24.30	deposit	2023-12-19
8229	470	311.10	deposit	2023-02-16
8230	811	354.50	withdrawal	2023-06-12
8231	1676	176.70	deposit	2023-08-05
8232	228	352.40	deposit	2024-04-29
8233	1620	95.30	deposit	2024-03-13
8234	1230	220.40	deposit	2023-05-27
8235	1570	471.60	deposit	2023-06-30
8236	752	161.80	withdrawal	2024-03-07
8237	139	235.80	withdrawal	2023-11-15
8238	1055	233.80	withdrawal	2023-06-11
8239	190	105.10	withdrawal	2023-11-30
8240	791	104.50	withdrawal	2024-04-11
8241	1303	257.80	withdrawal	2024-01-05
8242	1168	478.10	withdrawal	2023-03-05
8243	1755	214.70	deposit	2023-05-22
8244	542	237.30	deposit	2024-04-05
8245	1130	491.30	withdrawal	2023-02-06
8246	1386	64.60	deposit	2024-05-31
8247	1511	219.10	deposit	2024-04-19
8248	951	197.70	withdrawal	2023-11-03
8249	1740	237.60	deposit	2024-04-10
8250	1187	18.20	deposit	2023-10-12
8251	72	31.10	deposit	2023-03-30
8252	1181	481.10	deposit	2023-07-18
8253	257	476.60	withdrawal	2024-03-18
8254	425	320.10	deposit	2023-03-13
8255	1098	46.50	withdrawal	2023-03-19
8256	605	144.70	withdrawal	2023-10-14
8257	1668	192.40	deposit	2023-10-04
8258	1424	292.20	deposit	2023-06-24
8259	1752	396.30	withdrawal	2024-03-10
8260	1272	94.20	withdrawal	2024-03-25
8261	641	343.30	deposit	2024-01-09
8262	1182	281.40	deposit	2024-03-17
8263	1576	489.00	deposit	2024-03-29
8264	347	36.60	deposit	2023-10-28
8265	556	73.90	withdrawal	2023-07-15
8266	1034	268.20	withdrawal	2023-02-27
8267	1264	464.00	deposit	2023-01-09
8268	565	45.30	deposit	2023-04-21
8269	1716	447.80	withdrawal	2023-11-26
8270	1224	413.40	withdrawal	2023-05-27
8271	1053	210.80	deposit	2023-01-04
8272	870	142.30	withdrawal	2023-05-04
8273	1065	488.60	deposit	2023-12-02
8274	1266	203.50	deposit	2024-02-01
8275	782	407.10	withdrawal	2023-05-30
8276	1413	315.00	withdrawal	2023-06-10
8277	1672	56.20	withdrawal	2023-10-09
8278	1733	336.40	withdrawal	2023-09-23
8279	1031	393.40	deposit	2023-11-23
8280	938	118.20	deposit	2024-04-26
8281	888	488.20	deposit	2023-12-08
8282	970	221.50	deposit	2024-03-04
8283	258	325.50	deposit	2023-10-24
8284	20	190.50	deposit	2024-02-20
8285	1232	256.70	deposit	2023-09-15
8286	1217	40.80	deposit	2024-03-07
8287	11	397.80	withdrawal	2024-02-13
8288	1776	300.20	withdrawal	2024-05-24
8289	1167	386.00	withdrawal	2023-11-11
8290	1076	419.20	withdrawal	2024-04-30
8291	269	331.80	withdrawal	2023-10-24
8292	973	386.70	withdrawal	2024-02-24
8293	215	208.40	withdrawal	2023-06-08
8294	1061	364.60	withdrawal	2023-04-29
8295	93	493.90	deposit	2023-04-22
8296	408	450.80	withdrawal	2023-05-02
8297	1559	390.60	deposit	2023-10-08
8298	1532	423.80	withdrawal	2023-12-11
8299	1150	435.80	deposit	2023-06-17
8300	54	384.30	withdrawal	2023-08-12
8301	1555	372.80	deposit	2024-01-17
8302	1370	160.20	deposit	2023-01-04
8303	431	401.80	deposit	2023-07-18
8304	1657	107.30	deposit	2023-05-07
8305	362	397.20	deposit	2024-04-02
8306	733	413.80	deposit	2023-11-19
8307	350	112.40	deposit	2024-02-18
8308	453	169.30	withdrawal	2023-06-02
8309	1492	217.20	withdrawal	2024-03-29
8310	103	489.70	deposit	2024-04-09
8311	41	400.40	deposit	2023-09-13
8312	657	272.30	deposit	2023-09-25
8313	1644	37.80	deposit	2023-12-05
8314	76	237.50	withdrawal	2023-08-14
8315	722	269.30	withdrawal	2023-06-27
8316	1489	346.00	withdrawal	2023-03-04
8317	832	80.50	withdrawal	2024-01-28
8318	1274	14.30	deposit	2024-05-09
8319	1287	100.60	withdrawal	2024-01-25
8320	1324	36.60	deposit	2023-06-27
8321	1674	333.20	deposit	2023-03-05
8322	1128	427.30	deposit	2023-12-25
8323	1393	69.60	withdrawal	2023-08-09
8324	1106	225.20	withdrawal	2023-05-24
8325	1376	16.20	withdrawal	2024-05-29
8326	1567	228.20	deposit	2023-09-11
8327	1367	183.20	deposit	2023-08-13
8328	1793	106.30	withdrawal	2024-05-01
8329	272	332.90	deposit	2023-11-09
8330	1321	150.30	deposit	2024-02-10
8331	545	256.50	deposit	2023-06-15
8332	15	343.10	deposit	2023-02-24
8333	1699	134.00	withdrawal	2024-05-10
8334	1307	263.00	withdrawal	2024-02-13
8335	988	275.90	withdrawal	2024-03-06
8336	70	172.60	deposit	2024-05-16
8337	1681	278.70	deposit	2023-11-22
8338	268	253.80	deposit	2023-06-27
8339	1666	51.00	withdrawal	2023-09-24
8340	1652	321.60	withdrawal	2024-02-10
8341	1484	189.20	withdrawal	2023-07-09
8342	1285	86.80	deposit	2023-09-06
8343	1574	171.60	deposit	2023-01-04
8344	1066	338.80	withdrawal	2024-05-31
8345	761	337.10	deposit	2023-02-22
8346	313	249.40	withdrawal	2023-12-06
8347	393	261.80	withdrawal	2023-06-29
8348	190	347.00	withdrawal	2023-07-12
8349	1462	355.40	withdrawal	2024-05-18
8350	217	41.70	withdrawal	2023-02-16
8351	411	17.80	deposit	2023-04-23
8352	957	208.90	deposit	2023-12-12
8353	188	417.10	withdrawal	2023-05-02
8354	1499	118.00	withdrawal	2023-06-08
8355	664	402.50	deposit	2024-02-19
8356	1667	283.80	deposit	2023-09-08
8357	1171	448.70	deposit	2023-01-08
8358	1	261.30	withdrawal	2023-01-01
8359	1729	329.80	withdrawal	2023-01-01
8360	1184	330.40	deposit	2023-05-10
8361	1183	228.80	withdrawal	2024-03-07
8362	1399	323.40	deposit	2024-05-15
8363	572	28.60	withdrawal	2023-10-24
8364	1554	333.50	withdrawal	2023-02-17
8365	784	338.30	withdrawal	2024-03-13
8366	622	395.20	withdrawal	2023-06-10
8367	587	82.10	withdrawal	2023-04-20
8368	133	207.20	deposit	2023-03-15
8369	1151	187.00	deposit	2023-10-27
8370	486	120.80	deposit	2023-01-14
8371	64	137.30	withdrawal	2023-10-10
8372	610	39.10	withdrawal	2024-02-28
8373	701	14.60	withdrawal	2023-06-01
8374	1791	433.60	withdrawal	2023-09-11
8375	303	447.30	deposit	2023-04-13
8376	778	70.80	withdrawal	2023-08-16
8377	1573	76.40	withdrawal	2023-11-30
8378	1153	450.30	deposit	2024-02-15
8379	824	272.60	deposit	2024-03-26
8380	1443	429.60	withdrawal	2023-02-12
8381	94	441.80	deposit	2024-02-10
8382	12	330.20	deposit	2024-04-10
8383	21	453.90	deposit	2024-04-06
8384	662	150.10	withdrawal	2023-08-27
8385	316	83.20	deposit	2023-11-19
8386	1000	372.50	deposit	2024-05-21
8387	1494	57.00	deposit	2023-07-09
8388	572	165.20	withdrawal	2024-02-24
8389	988	105.10	deposit	2023-03-30
8390	501	42.70	withdrawal	2023-01-19
8391	112	150.20	withdrawal	2024-03-23
8392	1692	6.20	withdrawal	2024-02-13
8393	1450	289.40	deposit	2024-01-18
8394	802	179.80	deposit	2024-02-05
8395	451	185.20	deposit	2023-06-20
8396	226	412.10	deposit	2023-11-24
8397	1239	350.90	withdrawal	2023-09-10
8398	1235	449.60	deposit	2023-04-08
8399	1759	53.50	deposit	2023-09-16
8400	155	400.80	withdrawal	2023-09-26
8401	317	379.20	withdrawal	2023-04-02
8402	524	51.30	withdrawal	2023-04-09
8403	1408	37.30	withdrawal	2023-07-24
8404	912	275.00	deposit	2024-04-12
8405	1100	406.10	deposit	2024-01-12
8406	898	318.80	deposit	2023-06-27
8407	1417	179.00	deposit	2023-11-03
8408	1782	227.40	deposit	2023-03-11
8409	1148	230.00	withdrawal	2023-12-19
8410	908	388.20	withdrawal	2023-04-22
8411	83	171.20	withdrawal	2023-05-04
8412	1522	14.10	withdrawal	2024-04-02
8413	650	482.20	deposit	2024-01-27
8414	324	177.30	deposit	2023-08-25
8415	1713	395.10	withdrawal	2023-02-13
8416	414	439.50	withdrawal	2023-03-06
8417	1601	65.00	withdrawal	2024-05-13
8418	1311	202.80	withdrawal	2024-01-27
8419	194	458.60	withdrawal	2024-02-07
8420	172	180.10	withdrawal	2024-01-26
8421	935	214.90	withdrawal	2023-07-23
8422	324	413.20	deposit	2023-02-12
8423	892	462.50	withdrawal	2023-05-15
8424	1746	61.80	deposit	2024-01-28
8425	82	406.40	deposit	2023-05-28
8426	1014	420.50	withdrawal	2023-06-13
8427	641	218.20	withdrawal	2023-10-28
8428	1203	102.90	deposit	2023-08-04
8429	756	197.50	withdrawal	2024-01-15
8430	570	152.70	deposit	2023-11-26
8431	1743	164.50	withdrawal	2023-04-22
8432	1058	273.50	withdrawal	2023-06-16
8433	432	216.50	withdrawal	2024-03-29
8434	1346	389.90	withdrawal	2024-04-23
8435	516	8.90	deposit	2023-03-13
8436	565	98.40	withdrawal	2023-09-10
8437	1307	351.00	withdrawal	2023-07-14
8438	865	348.90	withdrawal	2023-05-26
8439	1186	376.70	withdrawal	2024-04-29
8440	253	497.00	withdrawal	2024-04-08
8441	735	173.30	deposit	2023-01-23
8442	1099	487.90	deposit	2023-11-22
8443	1723	402.00	withdrawal	2023-05-18
8444	1021	69.50	deposit	2023-10-09
8445	313	6.90	withdrawal	2023-06-15
8446	83	266.40	withdrawal	2024-02-09
8447	833	305.70	deposit	2023-01-04
8448	879	443.80	deposit	2024-02-13
8449	93	159.40	withdrawal	2023-11-22
8450	1646	17.60	deposit	2023-10-16
8451	905	407.50	deposit	2023-09-26
8452	162	426.70	withdrawal	2024-01-29
8453	233	419.40	withdrawal	2023-09-02
8454	1725	131.80	deposit	2024-02-03
8455	965	115.40	deposit	2024-03-31
8456	1186	416.90	deposit	2023-03-27
8457	468	360.50	withdrawal	2024-04-01
8458	673	10.70	deposit	2023-06-14
8459	1245	468.30	deposit	2024-02-01
8460	824	215.10	deposit	2023-11-07
8461	968	318.80	deposit	2023-06-12
8462	1030	27.90	withdrawal	2023-04-28
8463	496	344.90	withdrawal	2023-05-06
8464	570	204.10	deposit	2023-12-03
8465	1298	347.90	deposit	2024-02-23
8466	1741	490.40	withdrawal	2023-06-01
8467	1181	381.50	deposit	2024-01-28
8468	136	177.20	deposit	2023-04-11
8469	1526	239.60	withdrawal	2023-08-28
8470	698	290.80	deposit	2024-01-18
8471	646	149.80	withdrawal	2023-03-10
8472	1261	362.30	withdrawal	2023-02-13
8473	233	173.20	deposit	2024-03-19
8474	1282	391.80	withdrawal	2023-10-03
8475	1080	131.10	deposit	2023-10-24
8476	880	51.40	deposit	2024-05-19
8477	1540	52.80	deposit	2023-09-21
8478	671	154.20	deposit	2023-05-20
8479	1059	450.70	deposit	2023-12-28
8480	417	408.10	deposit	2023-06-06
8481	723	216.00	withdrawal	2024-05-28
8482	1413	487.20	deposit	2024-03-12
8483	1223	175.40	withdrawal	2024-01-01
8484	1699	38.70	withdrawal	2024-05-14
8485	828	158.20	deposit	2023-07-27
8486	989	14.10	withdrawal	2023-12-24
8487	1036	439.80	deposit	2023-11-09
8488	696	251.60	deposit	2023-10-18
8489	593	105.50	deposit	2024-01-28
8490	1307	159.00	withdrawal	2023-09-12
8491	1507	78.10	withdrawal	2023-03-18
8492	487	190.80	deposit	2024-05-21
8493	244	307.30	withdrawal	2023-12-19
8494	950	233.70	withdrawal	2023-06-21
8495	1576	462.20	deposit	2023-06-07
8496	258	5.80	deposit	2023-05-20
8497	212	33.90	withdrawal	2023-05-14
8498	215	399.50	withdrawal	2024-04-02
8499	1372	336.60	withdrawal	2023-10-13
8500	1648	27.40	withdrawal	2023-04-12
8501	1541	199.50	withdrawal	2023-01-14
8502	615	342.20	deposit	2023-09-01
8503	1486	376.70	deposit	2023-04-10
8504	833	486.10	withdrawal	2023-06-13
8505	40	366.30	deposit	2023-04-20
8506	42	492.10	deposit	2024-02-13
8507	1285	340.30	withdrawal	2023-11-19
8508	1476	198.30	withdrawal	2024-03-10
8509	1230	239.80	deposit	2023-08-06
8510	929	50.80	deposit	2023-06-25
8511	1513	480.90	deposit	2023-04-25
8512	1456	278.00	deposit	2023-12-08
8513	509	255.10	deposit	2023-04-09
8514	141	348.00	deposit	2023-12-18
8515	640	35.10	withdrawal	2023-03-15
8516	1132	201.80	deposit	2023-12-19
8517	1144	371.90	withdrawal	2024-05-24
8518	1102	373.30	deposit	2023-02-10
8519	1664	450.60	deposit	2023-04-20
8520	878	448.00	deposit	2023-02-28
8521	1292	286.80	deposit	2024-03-04
8522	243	265.60	withdrawal	2024-02-23
8523	804	34.50	withdrawal	2023-08-18
8524	905	257.60	deposit	2023-09-01
8525	473	412.60	deposit	2023-08-16
8526	1794	63.00	withdrawal	2023-12-24
8527	233	213.00	withdrawal	2023-10-06
8528	1578	460.60	deposit	2023-10-09
8529	1578	128.30	withdrawal	2023-05-25
8530	220	447.30	withdrawal	2023-10-19
8531	797	443.70	deposit	2023-07-11
8532	862	459.10	deposit	2024-04-16
8533	501	452.70	deposit	2024-04-08
8534	1699	283.70	deposit	2023-03-06
8535	1194	261.50	withdrawal	2023-06-16
8536	1090	217.20	deposit	2024-05-02
8537	1089	44.50	deposit	2023-03-01
8538	153	334.20	deposit	2024-04-06
8539	1448	301.50	withdrawal	2023-02-26
8540	499	443.20	withdrawal	2023-04-23
8541	725	370.80	withdrawal	2023-04-13
8542	994	9.40	deposit	2023-06-22
8543	151	203.60	withdrawal	2023-04-25
8544	458	159.30	withdrawal	2023-11-26
8545	1554	147.00	deposit	2024-01-31
8546	1285	188.00	deposit	2023-03-25
8547	86	348.70	withdrawal	2023-10-13
8548	55	492.50	deposit	2023-10-21
8549	420	92.00	withdrawal	2023-06-23
8550	499	222.30	withdrawal	2023-07-29
8551	801	267.70	withdrawal	2023-08-27
8552	1759	458.00	deposit	2024-04-29
8553	1214	267.40	withdrawal	2024-03-06
8554	1182	296.30	withdrawal	2023-04-28
8555	777	178.70	withdrawal	2024-05-19
8556	1740	112.60	deposit	2023-03-20
8557	897	59.20	withdrawal	2023-01-27
8558	101	185.10	withdrawal	2024-05-19
8559	318	491.30	deposit	2023-01-16
8560	338	369.40	withdrawal	2023-09-02
8561	86	450.70	withdrawal	2023-12-18
8562	266	496.70	deposit	2023-12-20
8563	1546	484.00	deposit	2023-12-17
8564	1567	290.80	withdrawal	2023-08-11
8565	1746	211.30	deposit	2023-07-06
8566	214	303.00	withdrawal	2023-10-13
8567	965	271.00	deposit	2024-02-21
8568	484	166.00	withdrawal	2024-03-20
8569	622	124.10	withdrawal	2024-04-27
8570	1407	389.10	withdrawal	2024-04-20
8571	1020	19.10	withdrawal	2024-05-23
8572	1605	173.50	deposit	2023-03-21
8573	698	371.90	withdrawal	2024-03-09
8574	1238	467.40	deposit	2023-02-27
8575	511	491.70	deposit	2023-05-20
8576	420	193.80	deposit	2023-02-01
8577	1540	416.30	deposit	2023-06-19
8578	613	251.70	withdrawal	2024-01-15
8579	244	184.20	withdrawal	2023-01-23
8580	512	151.70	deposit	2023-03-04
8581	879	359.70	withdrawal	2023-04-25
8582	537	472.30	deposit	2023-03-10
8583	137	228.80	withdrawal	2023-01-06
8584	1089	443.60	deposit	2023-06-20
8585	1040	279.10	deposit	2023-12-19
8586	675	475.40	withdrawal	2023-07-30
8587	1142	25.90	deposit	2024-01-09
8588	1132	238.40	deposit	2024-02-11
8589	630	326.70	deposit	2024-01-30
8590	1101	222.80	deposit	2023-02-13
8591	369	486.00	withdrawal	2023-12-14
8592	17	259.20	deposit	2024-04-13
8593	1027	281.40	deposit	2023-08-16
8594	1299	125.60	withdrawal	2024-04-26
8595	732	382.10	withdrawal	2023-07-25
8596	638	499.50	deposit	2023-09-12
8597	1465	204.50	deposit	2023-09-23
8598	836	72.60	withdrawal	2023-05-11
8599	275	162.60	withdrawal	2024-01-30
8600	1377	383.40	deposit	2023-10-18
8601	1624	192.00	withdrawal	2024-04-15
8602	1640	497.60	deposit	2023-09-18
8603	78	16.20	deposit	2023-09-20
8604	926	195.30	deposit	2024-01-05
8605	1256	160.20	withdrawal	2023-08-16
8606	1497	189.70	deposit	2023-01-03
8607	1383	32.30	deposit	2023-06-17
8608	1474	124.30	withdrawal	2024-05-27
8609	520	327.10	deposit	2023-10-22
8610	340	454.20	withdrawal	2023-12-01
8611	1242	7.80	deposit	2023-03-02
8612	498	404.30	withdrawal	2023-04-30
8613	1376	185.50	deposit	2024-03-22
8614	507	381.00	withdrawal	2023-10-27
8615	803	316.10	deposit	2023-08-10
8616	1650	100.10	withdrawal	2023-09-25
8617	1496	210.50	deposit	2023-11-20
8618	1172	33.90	withdrawal	2024-02-17
8619	1180	372.70	withdrawal	2024-05-17
8620	478	112.80	withdrawal	2023-09-26
8621	1029	306.10	deposit	2023-06-06
8622	571	157.70	withdrawal	2023-05-08
8623	290	457.80	deposit	2023-05-31
8624	9	162.50	withdrawal	2024-03-28
8625	1452	245.40	deposit	2023-11-10
8626	1705	25.10	withdrawal	2023-03-17
8627	1732	436.60	withdrawal	2024-02-28
8628	1215	482.40	withdrawal	2023-06-16
8629	1605	224.00	withdrawal	2023-01-16
8630	437	389.00	withdrawal	2023-11-14
8631	614	264.70	deposit	2023-06-28
8632	934	150.70	withdrawal	2023-01-23
8633	1321	412.00	deposit	2023-02-23
8634	943	235.70	withdrawal	2023-12-22
8635	847	174.50	deposit	2023-02-08
8636	1246	45.50	deposit	2023-05-25
8637	573	411.10	withdrawal	2023-11-10
8638	1620	222.60	deposit	2023-10-01
8639	1647	347.20	deposit	2024-03-05
8640	1253	420.00	deposit	2023-04-23
8641	1469	70.70	withdrawal	2023-11-15
8642	915	188.90	withdrawal	2023-10-29
8643	1231	39.60	withdrawal	2024-01-03
8644	1591	80.80	withdrawal	2023-03-27
8645	1033	438.30	deposit	2024-04-24
8646	533	41.70	deposit	2024-03-16
8647	1134	73.70	deposit	2023-10-13
8648	212	79.80	withdrawal	2024-04-29
8649	967	123.80	withdrawal	2023-10-14
8650	1319	345.50	withdrawal	2023-03-07
8651	655	488.60	deposit	2023-07-22
8652	1729	382.50	withdrawal	2023-11-27
8653	1177	483.20	withdrawal	2023-06-24
8654	1596	496.50	deposit	2024-03-08
8655	1667	448.00	deposit	2023-07-31
8656	1379	168.70	withdrawal	2023-11-20
8657	1413	30.10	withdrawal	2023-02-02
8658	534	105.90	deposit	2023-06-29
8659	798	347.30	deposit	2023-01-16
8660	1459	318.50	withdrawal	2023-06-12
8661	621	99.60	deposit	2023-04-02
8662	1648	29.60	withdrawal	2024-04-29
8663	83	40.80	withdrawal	2023-10-13
8664	1504	354.30	deposit	2023-02-07
8665	571	394.70	withdrawal	2023-01-09
8666	190	163.50	deposit	2024-03-06
8667	1109	41.90	deposit	2024-01-12
8668	638	457.70	withdrawal	2023-12-25
8669	1049	229.80	withdrawal	2023-04-10
8670	427	442.50	deposit	2024-03-11
8671	316	461.00	withdrawal	2023-01-03
8672	714	284.70	deposit	2023-10-18
8673	1410	467.80	withdrawal	2023-09-29
8674	621	63.10	withdrawal	2023-10-23
8675	1570	280.40	withdrawal	2024-04-02
8676	75	373.80	withdrawal	2023-12-17
8677	1748	330.90	withdrawal	2023-02-17
8678	1125	58.50	deposit	2024-05-02
8679	910	223.10	deposit	2024-03-01
8680	867	428.70	deposit	2023-06-04
8681	801	86.50	deposit	2024-05-03
8682	776	286.80	deposit	2023-05-21
8683	1085	75.40	withdrawal	2023-09-05
8684	297	128.30	deposit	2023-05-28
8685	1622	217.60	withdrawal	2024-04-19
8686	1352	175.70	deposit	2023-12-12
8687	442	194.80	withdrawal	2024-05-03
8688	1662	51.00	deposit	2023-06-27
8689	142	374.10	deposit	2023-12-02
8690	1256	34.30	withdrawal	2023-08-20
8691	824	277.60	deposit	2023-02-13
8692	1570	16.50	deposit	2023-05-16
8693	204	284.00	withdrawal	2023-01-16
8694	1386	355.10	withdrawal	2023-09-23
8695	1217	10.40	deposit	2023-11-13
8696	1138	419.30	deposit	2024-03-30
8697	1463	111.20	withdrawal	2023-06-15
8698	1678	380.10	withdrawal	2023-06-08
8699	964	153.80	withdrawal	2023-09-13
8700	279	454.00	withdrawal	2023-04-25
8701	1557	79.90	deposit	2023-10-23
8702	1489	212.90	withdrawal	2023-09-26
8703	604	408.70	deposit	2024-02-05
8704	210	40.00	withdrawal	2023-08-28
8705	30	133.10	deposit	2023-02-18
8706	1366	104.70	deposit	2024-05-01
8707	946	436.10	deposit	2023-07-05
8708	412	133.00	deposit	2023-04-07
8709	465	309.90	deposit	2024-02-26
8710	472	484.60	deposit	2024-05-19
8711	337	488.90	withdrawal	2023-12-20
8712	779	121.60	withdrawal	2023-02-08
8713	1486	239.60	deposit	2023-11-14
8714	128	492.90	withdrawal	2023-10-29
8715	869	236.60	withdrawal	2024-01-07
8716	1068	5.20	withdrawal	2024-01-13
8717	1346	106.20	deposit	2023-04-05
8718	448	151.30	deposit	2023-06-15
8719	1468	439.50	withdrawal	2023-01-25
8720	961	256.80	withdrawal	2023-07-12
8721	395	368.80	deposit	2023-12-22
8722	1618	172.60	withdrawal	2023-06-20
8723	796	175.50	withdrawal	2023-07-19
8724	404	196.60	deposit	2023-03-23
8725	116	75.10	withdrawal	2024-01-01
8726	756	7.70	withdrawal	2023-01-08
8727	30	458.30	withdrawal	2023-05-06
8728	1091	278.80	withdrawal	2023-07-15
8729	680	290.50	withdrawal	2023-12-15
8730	1205	473.30	withdrawal	2023-01-22
8731	2	112.50	withdrawal	2023-08-03
8732	452	461.30	deposit	2023-04-18
8733	845	72.60	deposit	2023-12-18
8734	162	31.70	deposit	2023-08-18
8735	184	126.20	withdrawal	2024-02-08
8736	1318	170.70	withdrawal	2024-05-28
8737	1118	64.30	withdrawal	2023-11-03
8738	1315	23.30	deposit	2023-05-08
8739	543	174.70	withdrawal	2023-01-28
8740	49	471.20	withdrawal	2023-07-12
8741	350	461.20	deposit	2024-05-18
8742	1080	395.60	withdrawal	2024-03-27
8743	106	428.80	withdrawal	2023-02-14
8744	918	208.00	withdrawal	2023-06-26
8745	760	310.30	deposit	2023-07-16
8746	1307	125.80	withdrawal	2023-03-12
8747	192	279.50	withdrawal	2023-04-07
8748	574	81.30	withdrawal	2023-01-20
8749	462	56.60	deposit	2024-02-04
8750	1537	75.50	deposit	2024-01-31
8751	1011	355.20	deposit	2024-03-07
8752	1178	157.10	withdrawal	2023-05-03
8753	1299	383.50	deposit	2023-03-08
8754	1173	443.80	withdrawal	2023-07-05
8755	1049	81.60	deposit	2023-07-07
8756	828	240.60	deposit	2023-06-27
8757	1691	209.00	withdrawal	2023-06-11
8758	1658	438.50	deposit	2023-11-30
8759	1346	141.30	deposit	2024-01-26
8760	1454	172.50	withdrawal	2024-01-23
8761	1178	215.90	withdrawal	2023-05-23
8762	709	214.80	deposit	2023-01-01
8763	1316	456.50	deposit	2023-01-23
8764	1656	104.40	deposit	2023-12-16
8765	1576	445.80	deposit	2023-06-10
8766	314	420.50	deposit	2023-06-22
8767	1674	129.80	withdrawal	2023-02-14
8768	1348	265.40	deposit	2023-05-15
8769	977	191.60	withdrawal	2023-04-12
8770	1379	106.30	withdrawal	2023-07-07
8771	972	253.80	deposit	2023-05-09
8772	912	427.80	withdrawal	2023-09-13
8773	1385	469.60	deposit	2024-05-09
8774	109	37.30	deposit	2023-01-24
8775	1684	332.40	withdrawal	2024-01-04
8776	310	420.60	withdrawal	2024-03-16
8777	1747	107.10	withdrawal	2023-03-23
8778	1776	280.40	withdrawal	2023-12-24
8779	1386	126.70	deposit	2024-03-24
8780	1372	132.10	deposit	2024-01-27
8781	1071	229.60	withdrawal	2023-07-28
8782	1607	35.20	withdrawal	2023-03-03
8783	894	478.20	withdrawal	2023-11-18
8784	1004	39.20	withdrawal	2024-02-03
8785	1195	95.80	withdrawal	2024-03-31
8786	1565	485.20	deposit	2023-08-10
8787	1653	358.60	deposit	2023-04-09
8788	272	488.70	withdrawal	2023-10-13
8789	1461	468.40	withdrawal	2023-04-20
8790	148	180.90	deposit	2023-10-30
8791	278	401.40	deposit	2024-01-23
8792	1568	472.90	withdrawal	2023-01-22
8793	906	72.00	deposit	2024-01-26
8794	1688	142.40	deposit	2023-03-13
8795	1731	268.80	deposit	2024-03-31
8796	11	281.60	deposit	2024-04-28
8797	229	283.40	deposit	2023-09-08
8798	1022	55.10	withdrawal	2024-04-08
8799	48	367.30	withdrawal	2023-01-19
8800	1714	201.80	deposit	2023-02-10
8801	1028	198.80	deposit	2023-05-03
8802	1537	267.00	withdrawal	2023-11-22
8803	270	77.00	deposit	2023-12-16
8804	607	457.50	withdrawal	2023-12-22
8805	1038	106.40	withdrawal	2023-12-23
8806	92	270.70	deposit	2024-01-21
8807	1297	499.00	deposit	2023-03-18
8808	502	247.60	withdrawal	2023-05-09
8809	239	248.20	deposit	2023-04-09
8810	1071	325.20	withdrawal	2023-11-09
8811	1442	355.00	withdrawal	2023-10-11
8812	596	343.30	withdrawal	2023-05-24
8813	1748	218.00	withdrawal	2023-02-05
8814	104	270.00	deposit	2023-12-18
8815	1770	81.90	withdrawal	2023-11-07
8816	840	13.40	withdrawal	2024-02-19
8817	1222	350.50	deposit	2023-05-23
8818	174	225.70	withdrawal	2023-12-27
8819	1571	332.60	withdrawal	2023-11-16
8820	920	469.00	withdrawal	2024-03-23
8821	550	232.60	withdrawal	2023-10-04
8822	1028	144.80	deposit	2024-05-24
8823	1199	172.00	deposit	2023-08-21
8824	663	150.00	withdrawal	2024-01-09
8825	1635	460.80	deposit	2023-05-06
8826	1251	417.50	withdrawal	2024-05-18
8827	1588	239.80	withdrawal	2023-05-09
8828	997	482.70	deposit	2023-11-11
8829	791	301.40	deposit	2023-11-10
8830	1628	441.70	withdrawal	2024-01-08
8831	1105	181.10	deposit	2023-02-09
8832	1409	156.30	withdrawal	2023-11-08
8833	813	22.50	deposit	2023-11-19
8834	1111	94.50	deposit	2023-07-07
8835	150	93.30	withdrawal	2023-05-29
8836	86	331.80	withdrawal	2023-10-12
8837	780	226.60	withdrawal	2023-07-15
8838	1288	180.30	withdrawal	2023-03-02
8839	1355	49.20	withdrawal	2023-12-14
8840	293	198.40	withdrawal	2023-03-28
8841	1081	209.30	deposit	2023-04-30
8842	1218	134.10	deposit	2023-07-14
8843	1363	269.70	withdrawal	2024-02-08
8844	1427	268.40	withdrawal	2023-09-28
8845	674	449.30	withdrawal	2023-07-10
8846	1628	202.00	deposit	2024-01-28
8847	330	50.50	withdrawal	2024-04-06
8848	1110	315.50	withdrawal	2023-09-28
8849	1614	13.60	deposit	2024-01-15
8850	1366	297.10	withdrawal	2023-06-06
8851	1011	64.20	deposit	2023-01-14
8852	186	68.10	deposit	2023-03-26
8853	266	385.20	deposit	2023-10-23
8854	583	120.30	withdrawal	2023-04-16
8855	478	328.20	withdrawal	2024-03-06
8856	1709	285.40	deposit	2023-03-18
8857	509	444.90	withdrawal	2023-12-25
8858	589	173.40	deposit	2023-04-09
8859	373	205.00	withdrawal	2023-07-18
8860	1007	354.80	deposit	2023-04-29
8861	289	78.50	deposit	2023-10-31
8862	149	51.00	withdrawal	2023-03-13
8863	840	198.40	withdrawal	2023-04-15
8864	760	304.60	withdrawal	2023-08-22
8865	785	108.10	deposit	2024-05-14
8866	757	372.30	withdrawal	2023-03-19
8867	1122	356.80	deposit	2023-06-06
8868	815	15.90	deposit	2023-11-26
8869	338	247.80	deposit	2023-02-12
8870	1430	324.80	withdrawal	2023-11-19
8871	801	453.20	deposit	2023-12-16
8872	213	475.80	withdrawal	2023-05-15
8873	1198	464.30	deposit	2023-10-26
8874	1516	419.50	withdrawal	2023-12-04
8875	191	412.90	withdrawal	2024-03-14
8876	1375	329.00	withdrawal	2023-01-06
8877	511	124.70	deposit	2023-03-17
8878	551	108.10	withdrawal	2023-04-13
8879	1277	146.20	withdrawal	2023-12-12
8880	57	112.40	withdrawal	2023-10-29
8881	957	456.10	withdrawal	2023-07-27
8882	852	231.40	deposit	2023-06-27
8883	625	411.10	withdrawal	2024-04-27
8884	297	86.60	deposit	2023-11-07
8885	1160	76.00	deposit	2023-11-29
8886	1301	286.10	deposit	2023-12-22
8887	192	331.10	withdrawal	2023-02-08
8888	560	300.40	deposit	2023-06-03
8889	257	209.00	deposit	2024-04-05
8890	1608	295.70	deposit	2023-10-06
8891	1542	357.80	withdrawal	2023-06-02
8892	1402	389.50	withdrawal	2024-01-18
8893	1773	357.10	deposit	2023-01-12
8894	275	463.70	deposit	2023-09-02
8895	1602	257.10	withdrawal	2023-12-23
8896	54	187.10	withdrawal	2023-04-01
8897	1253	341.40	withdrawal	2024-01-02
8898	62	92.30	deposit	2024-03-21
8899	1281	177.00	deposit	2024-02-24
8900	615	285.90	withdrawal	2023-02-09
8901	1699	69.40	withdrawal	2023-12-02
8902	303	201.90	deposit	2024-04-28
8903	1778	457.80	deposit	2023-11-07
8904	31	159.50	deposit	2024-04-23
8905	1418	323.70	deposit	2023-05-08
8906	1210	138.60	withdrawal	2024-05-07
8907	92	155.90	deposit	2023-10-25
8908	847	43.70	withdrawal	2023-02-27
8909	289	208.30	withdrawal	2024-03-13
8910	926	335.50	withdrawal	2023-05-30
8911	357	394.30	deposit	2023-12-02
8912	1787	48.90	withdrawal	2023-06-13
8913	112	389.80	deposit	2023-10-20
8914	909	489.90	withdrawal	2023-09-13
8915	1181	286.70	deposit	2023-11-17
8916	1280	24.00	deposit	2023-12-04
8917	1549	486.70	deposit	2024-01-19
8918	1059	435.20	deposit	2023-09-26
8919	1391	279.20	deposit	2024-04-26
8920	1755	265.40	withdrawal	2024-05-11
8921	1390	249.20	deposit	2023-02-13
8922	1280	321.70	withdrawal	2024-02-11
8923	357	157.80	withdrawal	2023-04-03
8924	1330	380.30	withdrawal	2023-01-23
8925	1471	328.10	withdrawal	2023-07-31
8926	279	257.70	withdrawal	2023-09-14
8927	650	138.70	withdrawal	2023-11-22
8928	45	277.50	deposit	2023-03-09
8929	1112	422.80	deposit	2023-05-21
8930	1057	229.90	deposit	2023-10-05
8931	179	19.80	withdrawal	2023-01-13
8932	1773	428.70	deposit	2024-01-06
8933	1493	292.90	withdrawal	2023-06-04
8934	789	115.90	withdrawal	2023-08-22
8935	32	287.50	deposit	2023-04-12
8936	630	235.30	withdrawal	2023-05-27
8937	495	421.20	withdrawal	2023-05-13
8938	571	21.40	withdrawal	2023-04-07
8939	528	317.90	withdrawal	2023-08-20
8940	1013	134.90	withdrawal	2024-02-05
8941	1311	229.50	withdrawal	2023-05-25
8942	1174	42.20	withdrawal	2024-01-14
8943	1	221.20	withdrawal	2024-03-13
8944	766	434.60	withdrawal	2024-01-02
8945	882	352.60	deposit	2024-01-04
8946	1424	173.70	deposit	2024-05-26
8947	1405	32.40	withdrawal	2023-08-02
8948	1694	146.90	deposit	2023-11-10
8949	157	482.30	deposit	2023-07-24
8950	1177	195.00	withdrawal	2024-05-15
8951	507	163.00	deposit	2023-01-21
8952	1735	319.50	withdrawal	2024-01-26
8953	209	5.60	deposit	2023-09-29
8954	1751	418.70	withdrawal	2024-01-29
8955	1724	273.20	deposit	2023-02-12
8956	21	449.10	deposit	2023-10-17
8957	1471	130.20	withdrawal	2023-12-05
8958	1768	485.00	withdrawal	2024-01-31
8959	1679	464.80	withdrawal	2023-10-30
8960	1194	408.20	withdrawal	2024-03-21
8961	851	397.70	withdrawal	2023-12-12
8962	1119	454.90	withdrawal	2023-02-25
8963	1118	317.20	deposit	2023-03-06
8964	1347	237.20	withdrawal	2023-05-05
8965	269	277.90	deposit	2024-02-22
8966	1616	40.80	deposit	2023-04-10
8967	1316	80.40	withdrawal	2023-03-29
8968	437	399.30	withdrawal	2023-10-27
8969	822	296.10	withdrawal	2023-10-29
8970	417	159.80	deposit	2024-03-13
8971	1521	55.00	withdrawal	2023-10-09
8972	120	252.20	withdrawal	2024-05-26
8973	530	56.90	withdrawal	2024-02-01
8974	1577	126.50	withdrawal	2023-06-07
8975	807	387.00	withdrawal	2023-11-19
8976	766	348.30	deposit	2023-08-29
8977	311	365.00	withdrawal	2023-03-21
8978	657	393.20	deposit	2024-05-13
8979	1202	260.00	withdrawal	2023-11-28
8980	633	378.30	withdrawal	2023-04-15
8981	1103	46.80	withdrawal	2023-07-12
8982	1760	499.40	withdrawal	2024-01-12
8983	379	340.60	withdrawal	2023-12-08
8984	867	249.50	deposit	2024-05-08
8985	1764	270.00	withdrawal	2023-09-12
8986	191	196.20	deposit	2024-03-11
8987	1732	185.40	withdrawal	2024-03-11
8988	1745	106.60	withdrawal	2023-04-04
8989	1608	95.30	withdrawal	2024-03-12
8990	448	10.20	deposit	2024-01-02
8991	1143	478.10	withdrawal	2024-01-18
8992	1540	319.30	withdrawal	2023-12-19
8993	1437	49.50	withdrawal	2024-03-15
8994	1331	209.20	deposit	2023-07-17
8995	490	379.30	withdrawal	2023-09-26
8996	1700	436.40	deposit	2023-04-04
8997	664	136.40	withdrawal	2024-02-03
8998	1059	372.00	withdrawal	2024-01-05
8999	365	110.40	withdrawal	2023-05-10
9000	741	390.50	deposit	2024-03-08
9001	1525	106.10	deposit	2023-01-08
9002	1641	417.10	deposit	2023-06-09
9003	1348	320.10	deposit	2024-03-31
9004	540	356.00	deposit	2023-10-30
9005	1060	393.40	deposit	2024-01-23
9006	1341	79.00	deposit	2023-09-13
9007	590	358.90	withdrawal	2024-01-25
9008	1740	234.40	withdrawal	2023-09-26
9009	91	246.70	deposit	2023-08-19
9010	1063	36.40	withdrawal	2023-09-01
9011	377	403.30	deposit	2023-06-14
9012	292	59.30	deposit	2023-07-27
9013	75	211.90	deposit	2024-01-27
9014	437	493.30	withdrawal	2023-07-22
9015	1758	497.40	withdrawal	2023-06-24
9016	479	76.00	deposit	2023-07-14
9017	121	70.80	withdrawal	2023-10-23
9018	1598	431.20	withdrawal	2024-02-05
9019	817	15.00	deposit	2023-06-05
9020	1771	67.30	deposit	2024-04-10
9021	901	153.20	deposit	2023-10-28
9022	173	17.40	deposit	2024-05-21
9023	1030	257.40	withdrawal	2023-03-09
9024	20	363.90	deposit	2023-09-22
9025	1362	288.70	deposit	2023-01-30
9026	1390	71.90	withdrawal	2023-04-07
9027	270	97.40	deposit	2024-02-10
9028	708	351.70	deposit	2024-04-18
9029	647	288.30	deposit	2023-08-20
9030	369	151.30	withdrawal	2023-10-06
9031	1601	98.30	deposit	2024-02-22
9032	29	489.30	deposit	2024-02-13
9033	1634	257.30	deposit	2023-07-20
9034	512	293.10	deposit	2023-07-28
9035	936	74.60	withdrawal	2023-02-16
9036	362	267.10	withdrawal	2023-09-08
9037	975	123.90	deposit	2023-03-14
9038	1593	53.00	withdrawal	2023-05-18
9039	329	363.70	withdrawal	2024-05-17
9040	1553	487.80	withdrawal	2023-09-26
9041	292	180.10	withdrawal	2023-07-01
9042	1020	184.00	deposit	2023-11-17
9043	397	259.10	deposit	2023-10-26
9044	652	421.20	deposit	2023-01-12
9045	5	246.70	deposit	2023-03-27
9046	217	109.00	withdrawal	2023-03-05
9047	631	274.10	withdrawal	2023-08-21
9048	231	247.20	withdrawal	2023-09-24
9049	386	77.10	withdrawal	2023-03-03
9050	441	294.40	deposit	2023-09-08
9051	719	186.10	withdrawal	2023-08-11
9052	1186	430.50	withdrawal	2023-04-06
9053	593	324.50	deposit	2023-07-03
9054	1700	128.40	withdrawal	2024-02-08
9055	731	148.50	withdrawal	2024-02-21
9056	732	370.00	withdrawal	2023-05-21
9057	1136	357.40	withdrawal	2023-08-21
9058	1056	308.90	deposit	2023-08-10
9059	1799	11.70	withdrawal	2023-08-06
9060	138	299.10	deposit	2023-01-03
9061	1689	489.50	deposit	2023-03-25
9062	1030	396.40	deposit	2024-03-25
9063	1140	129.80	withdrawal	2023-05-11
9064	369	72.70	withdrawal	2023-04-18
9065	1368	233.60	withdrawal	2024-05-31
9066	784	266.20	deposit	2023-08-15
9067	1129	458.90	deposit	2024-04-21
9068	1225	407.00	withdrawal	2023-03-11
9069	1160	159.40	deposit	2024-01-10
9070	420	458.50	withdrawal	2023-11-12
9071	1467	243.00	deposit	2023-11-07
9072	1796	381.40	withdrawal	2024-01-29
9073	1172	26.20	withdrawal	2023-04-26
9074	1395	333.20	deposit	2023-11-06
9075	1344	203.20	deposit	2023-05-11
9076	659	491.30	withdrawal	2023-05-25
9077	284	277.00	withdrawal	2024-03-16
9078	596	458.00	withdrawal	2023-02-27
9079	616	162.10	withdrawal	2024-05-28
9080	735	436.00	deposit	2023-11-06
9081	200	457.30	withdrawal	2023-03-21
9082	220	408.70	withdrawal	2023-10-21
9083	1646	328.90	withdrawal	2023-03-22
9084	1239	44.70	withdrawal	2023-09-09
9085	206	264.20	withdrawal	2023-09-19
9086	1435	221.60	deposit	2024-01-09
9087	719	297.40	withdrawal	2023-04-20
9088	149	308.90	deposit	2023-02-03
9089	1337	46.00	deposit	2024-05-12
9090	339	434.70	deposit	2023-08-07
9091	1213	379.00	withdrawal	2023-12-29
9092	30	393.10	withdrawal	2023-03-04
9093	966	83.40	deposit	2023-03-19
9094	196	499.40	deposit	2023-05-11
9095	1535	232.40	deposit	2024-02-18
9096	1166	58.90	withdrawal	2023-10-07
9097	1624	28.70	withdrawal	2023-06-17
9098	24	162.10	deposit	2023-11-06
9099	1372	140.40	deposit	2023-07-08
9100	774	447.50	withdrawal	2023-05-27
9101	1053	178.80	withdrawal	2023-12-19
9102	262	433.00	deposit	2024-04-29
9103	337	265.20	deposit	2023-12-16
9104	1300	459.20	deposit	2023-08-18
9105	1271	397.00	withdrawal	2023-12-07
9106	260	98.20	withdrawal	2023-10-04
9107	132	58.80	withdrawal	2024-02-09
9108	1757	43.60	deposit	2024-04-16
9109	1546	226.20	deposit	2024-01-03
9110	1685	426.40	withdrawal	2024-03-04
9111	1082	189.40	withdrawal	2023-03-20
9112	786	228.20	withdrawal	2023-02-06
9113	1341	243.30	withdrawal	2023-08-06
9114	459	277.70	deposit	2023-04-13
9115	864	150.80	withdrawal	2023-08-22
9116	1031	315.70	withdrawal	2023-01-13
9117	133	134.70	withdrawal	2023-07-26
9118	430	413.90	withdrawal	2023-01-21
9119	423	84.50	withdrawal	2023-05-05
9120	1365	157.70	deposit	2024-03-26
9121	675	305.30	deposit	2023-05-03
9122	268	420.30	deposit	2023-10-12
9123	741	474.50	deposit	2024-05-22
9124	1656	433.00	withdrawal	2024-04-06
9125	1689	481.00	deposit	2024-04-08
9126	583	305.90	withdrawal	2023-12-24
9127	851	355.80	deposit	2023-07-22
9128	383	120.10	withdrawal	2023-12-20
9129	310	382.40	withdrawal	2023-05-12
9130	27	163.20	deposit	2024-04-22
9131	1716	293.30	withdrawal	2024-02-01
9132	801	435.40	deposit	2023-05-09
9133	345	117.30	withdrawal	2023-01-25
9134	1675	316.40	withdrawal	2023-10-03
9135	1750	94.90	deposit	2023-09-23
9136	1214	21.60	deposit	2023-03-14
9137	1240	500.90	deposit	2024-01-10
9138	1764	23.80	deposit	2023-02-14
9139	913	35.20	withdrawal	2023-12-31
9140	1274	16.90	withdrawal	2023-09-26
9141	1356	89.60	withdrawal	2023-05-16
9142	989	272.00	withdrawal	2024-02-09
9143	994	187.40	deposit	2023-10-19
9144	798	33.20	withdrawal	2023-11-22
9145	36	96.10	withdrawal	2023-04-08
9146	1090	399.80	deposit	2023-09-23
9147	1046	430.60	withdrawal	2023-08-20
9148	102	143.60	withdrawal	2023-03-21
9149	178	298.00	withdrawal	2024-03-03
9150	1459	104.80	withdrawal	2024-03-13
9151	205	161.20	withdrawal	2023-06-14
9152	1686	163.70	deposit	2024-05-05
9153	868	295.90	withdrawal	2023-04-01
9154	1322	359.50	withdrawal	2024-02-27
9155	1251	194.40	deposit	2023-04-05
9156	240	339.50	deposit	2024-05-22
9157	498	151.40	deposit	2024-05-26
9158	1155	40.90	withdrawal	2023-12-02
9159	520	228.40	withdrawal	2023-12-05
9160	1672	281.90	withdrawal	2024-04-14
9161	847	297.60	withdrawal	2024-01-05
9162	1571	451.00	deposit	2023-04-19
9163	148	153.90	withdrawal	2024-01-05
9164	1736	89.30	deposit	2024-01-07
9165	1098	289.00	deposit	2023-11-12
9166	438	309.50	deposit	2023-11-04
9167	145	208.20	withdrawal	2024-05-03
9168	443	79.40	deposit	2024-03-11
9169	969	334.40	deposit	2023-02-24
9170	712	164.90	withdrawal	2023-05-06
9171	671	125.00	deposit	2023-11-21
9172	974	127.10	withdrawal	2023-02-09
9173	1056	247.20	withdrawal	2023-12-10
9174	566	55.50	withdrawal	2023-08-12
9175	146	15.00	deposit	2023-07-20
9176	203	222.70	withdrawal	2024-05-26
9177	1	101.70	deposit	2024-02-17
9178	550	74.60	deposit	2023-02-13
9179	957	221.40	withdrawal	2024-05-09
9180	1750	195.70	withdrawal	2023-07-27
9181	1104	104.20	withdrawal	2024-05-15
9182	1447	73.20	withdrawal	2023-12-03
9183	703	429.90	deposit	2024-05-07
9184	686	151.90	deposit	2023-12-28
9185	268	12.80	withdrawal	2024-01-24
9186	1523	53.30	withdrawal	2023-08-23
9187	443	234.60	deposit	2024-04-23
9188	1485	281.90	withdrawal	2023-03-01
9189	384	428.40	deposit	2023-02-22
9190	348	423.50	deposit	2024-02-01
9191	869	42.20	deposit	2024-05-17
9192	1098	370.40	deposit	2023-03-24
9193	126	431.30	deposit	2024-01-06
9194	1182	326.90	withdrawal	2024-03-05
9195	426	61.70	deposit	2023-03-13
9196	1654	101.30	withdrawal	2023-11-14
9197	676	343.60	deposit	2023-03-29
9198	132	45.60	deposit	2024-02-06
9199	349	237.50	withdrawal	2023-08-26
9200	1167	376.90	withdrawal	2023-09-23
9201	552	143.90	withdrawal	2023-06-19
9202	668	41.10	deposit	2023-08-01
9203	1122	261.80	deposit	2024-03-31
9204	914	272.20	deposit	2023-03-06
9205	307	369.00	deposit	2023-07-05
9206	867	425.10	withdrawal	2024-04-29
9207	801	352.60	withdrawal	2023-04-11
9208	1731	423.10	withdrawal	2023-03-08
9209	1094	245.10	withdrawal	2023-08-18
9210	1382	176.40	deposit	2023-01-21
9211	1707	467.40	withdrawal	2023-01-16
9212	1095	129.60	withdrawal	2023-05-03
9213	1295	333.80	withdrawal	2024-02-14
9214	1558	170.30	deposit	2023-12-04
9215	236	209.60	withdrawal	2023-07-11
9216	116	237.60	withdrawal	2023-10-11
9217	1700	63.40	withdrawal	2024-01-05
9218	1651	108.10	withdrawal	2024-01-06
9219	906	190.80	withdrawal	2023-08-06
9220	83	411.10	deposit	2023-12-19
9221	871	372.40	deposit	2023-12-26
9222	428	136.40	withdrawal	2023-07-15
9223	1711	435.20	deposit	2024-05-14
9224	1016	428.70	withdrawal	2023-05-11
9225	970	160.10	deposit	2024-05-29
9226	1192	39.20	deposit	2023-11-12
9227	1338	234.20	withdrawal	2023-01-28
9228	1099	170.00	withdrawal	2024-05-17
9229	1095	72.40	withdrawal	2023-01-28
9230	642	295.80	withdrawal	2024-02-27
9231	1258	449.10	withdrawal	2023-01-31
9232	228	163.40	deposit	2023-02-15
9233	359	144.20	deposit	2023-12-16
9234	567	96.70	deposit	2023-02-08
9235	870	254.00	deposit	2024-01-14
9236	753	127.30	withdrawal	2023-11-12
9237	316	239.80	deposit	2023-06-26
9238	1790	460.30	withdrawal	2023-11-15
9239	342	194.80	deposit	2023-10-10
9240	1704	487.80	withdrawal	2023-01-03
9241	807	209.50	withdrawal	2023-04-06
9242	34	170.80	deposit	2023-03-02
9243	159	280.60	withdrawal	2024-04-24
9244	587	274.10	deposit	2023-10-15
9245	853	85.60	withdrawal	2024-02-24
9246	262	407.60	withdrawal	2023-02-23
9247	1497	377.40	withdrawal	2023-03-05
9248	1664	143.30	withdrawal	2023-02-19
9249	1241	473.60	withdrawal	2024-03-04
9250	1792	461.20	deposit	2024-01-04
9251	339	486.80	deposit	2023-10-12
9252	1420	294.50	deposit	2023-12-28
9253	1052	33.00	deposit	2023-01-24
9254	1546	100.70	withdrawal	2023-08-15
9255	1268	363.00	deposit	2023-04-20
9256	1795	464.90	withdrawal	2023-05-23
9257	1521	434.00	deposit	2023-12-29
9258	519	237.90	deposit	2023-01-13
9259	1300	401.40	withdrawal	2024-01-05
9260	90	421.50	withdrawal	2023-12-03
9261	899	213.30	withdrawal	2023-05-29
9262	1535	58.20	deposit	2023-10-26
9263	415	240.00	withdrawal	2023-03-02
9264	21	451.70	deposit	2024-02-01
9265	906	184.80	withdrawal	2023-12-12
9266	1138	420.00	withdrawal	2023-09-14
9267	1328	198.90	deposit	2024-05-23
9268	54	370.20	withdrawal	2024-04-16
9269	307	294.00	withdrawal	2023-06-23
9270	497	219.20	deposit	2024-03-20
9271	72	14.20	withdrawal	2023-01-07
9272	745	215.50	deposit	2023-06-01
9273	1778	470.30	deposit	2024-05-08
9274	1238	491.80	withdrawal	2024-05-11
9275	1568	266.80	withdrawal	2023-09-09
9276	648	382.10	deposit	2024-02-25
9277	640	174.30	deposit	2023-04-17
9278	886	158.20	withdrawal	2023-12-11
9279	993	91.40	withdrawal	2023-07-28
9280	1373	96.20	withdrawal	2023-04-28
9281	1117	467.50	deposit	2023-06-15
9282	575	101.40	deposit	2023-07-09
9283	230	304.60	deposit	2024-03-29
9284	1632	231.80	deposit	2024-01-10
9285	62	60.70	withdrawal	2024-05-24
9286	1258	157.60	withdrawal	2023-02-10
9287	920	131.00	deposit	2023-08-05
9288	1709	126.40	withdrawal	2023-04-02
9289	109	327.80	deposit	2024-05-14
9290	1090	189.70	deposit	2024-02-13
9291	1078	332.60	withdrawal	2023-06-11
9292	1643	466.00	deposit	2024-01-03
9293	1552	69.70	withdrawal	2023-08-28
9294	500	210.10	withdrawal	2023-08-30
9295	594	338.40	withdrawal	2023-07-18
9296	1391	292.20	deposit	2023-06-08
9297	80	132.70	deposit	2023-04-29
9298	1306	282.40	deposit	2023-06-18
9299	1471	282.70	deposit	2023-09-15
9300	1496	388.00	withdrawal	2023-07-14
9301	871	13.30	deposit	2023-09-24
9302	1720	422.20	withdrawal	2024-01-21
9303	14	202.40	withdrawal	2023-02-21
9304	342	39.20	withdrawal	2024-02-26
9305	842	261.70	deposit	2023-06-25
9306	1608	266.40	deposit	2023-09-07
9307	1483	27.10	deposit	2023-08-23
9308	132	101.50	deposit	2023-08-10
9309	1331	173.90	deposit	2024-01-03
9310	1233	406.30	withdrawal	2023-10-14
9311	447	176.60	withdrawal	2024-05-19
9312	206	396.60	withdrawal	2023-04-26
9313	157	96.30	deposit	2023-10-26
9314	170	128.50	withdrawal	2023-02-14
9315	201	26.40	withdrawal	2024-02-16
9316	628	98.00	withdrawal	2023-12-30
9317	1333	164.10	withdrawal	2024-03-08
9318	1629	268.90	deposit	2024-02-16
9319	743	240.70	deposit	2023-08-18
9320	1490	261.90	withdrawal	2023-06-27
9321	12	115.10	withdrawal	2023-02-12
9322	485	319.10	withdrawal	2023-10-04
9323	1232	232.50	withdrawal	2023-02-01
9324	791	484.10	deposit	2023-03-27
9325	1521	465.60	withdrawal	2023-11-05
9326	1084	252.40	deposit	2024-04-27
9327	222	483.90	deposit	2023-12-07
9328	1366	466.90	deposit	2023-01-18
9329	1179	363.00	withdrawal	2023-07-04
9330	908	316.50	withdrawal	2023-10-01
9331	1485	7.70	deposit	2023-12-06
9332	903	31.40	withdrawal	2024-01-17
9333	29	463.60	deposit	2023-05-31
9334	776	293.40	withdrawal	2023-08-13
9335	464	499.00	deposit	2023-01-09
9336	43	471.40	withdrawal	2023-11-14
9337	1229	451.80	withdrawal	2024-04-13
9338	1374	140.60	withdrawal	2023-03-23
9339	968	163.40	deposit	2023-10-07
9340	291	93.00	deposit	2023-09-26
9341	450	488.30	deposit	2023-05-18
9342	164	282.90	withdrawal	2023-07-09
9343	1508	453.00	withdrawal	2023-04-06
9344	1668	395.40	withdrawal	2023-06-13
9345	773	143.40	withdrawal	2023-03-30
9346	815	35.40	withdrawal	2023-07-30
9347	153	209.10	deposit	2023-03-29
9348	201	382.40	deposit	2024-01-04
9349	258	425.80	deposit	2023-05-14
9350	1265	461.00	withdrawal	2023-09-15
9351	1228	156.70	deposit	2024-04-06
9352	933	94.40	deposit	2024-04-07
9353	1017	31.80	withdrawal	2023-07-08
9354	1364	397.30	deposit	2023-07-09
9355	1281	222.50	withdrawal	2023-10-30
9356	401	332.00	deposit	2024-04-13
9357	1497	119.30	deposit	2023-09-16
9358	714	491.90	deposit	2023-10-15
9359	1753	133.20	deposit	2024-04-08
9360	122	123.00	deposit	2023-01-26
9361	138	49.40	deposit	2023-06-25
9362	1673	352.50	deposit	2023-05-03
9363	337	497.10	withdrawal	2023-07-13
9364	1005	154.60	deposit	2024-03-31
9365	37	182.70	deposit	2023-06-18
9366	778	222.60	deposit	2023-10-26
9367	984	358.30	deposit	2023-04-14
9368	82	367.80	deposit	2023-04-24
9369	1586	139.00	deposit	2023-05-13
9370	1782	320.90	withdrawal	2023-09-05
9371	147	263.60	deposit	2023-06-09
9372	1648	51.10	deposit	2024-02-15
9373	1042	116.70	withdrawal	2024-04-12
9374	1206	396.00	withdrawal	2023-12-29
9375	742	104.90	deposit	2023-08-27
9376	1738	149.10	withdrawal	2024-05-23
9377	1057	69.80	withdrawal	2023-01-28
9378	1695	50.80	deposit	2024-04-14
9379	1668	441.90	withdrawal	2024-04-07
9380	1638	212.00	withdrawal	2023-10-20
9381	841	365.20	withdrawal	2023-05-30
9382	1031	201.00	withdrawal	2023-09-17
9383	1281	258.20	withdrawal	2023-08-24
9384	1106	64.10	withdrawal	2024-02-19
9385	611	267.40	deposit	2023-05-02
9386	666	354.40	deposit	2023-11-12
9387	1680	169.60	deposit	2023-11-11
9388	434	487.00	deposit	2024-03-20
9389	851	27.50	deposit	2024-01-11
9390	1593	420.10	withdrawal	2023-06-11
9391	109	499.70	deposit	2023-11-15
9392	1585	299.30	deposit	2023-02-11
9393	397	420.20	deposit	2024-05-09
9394	1518	422.30	withdrawal	2023-10-11
9395	1294	232.30	withdrawal	2023-08-09
9396	1472	358.20	withdrawal	2024-05-22
9397	1202	71.20	deposit	2023-09-25
9398	68	330.90	deposit	2023-06-09
9399	815	120.60	deposit	2023-01-21
9400	1019	452.40	deposit	2023-10-14
9401	1078	478.60	deposit	2023-03-05
9402	210	258.20	deposit	2023-10-01
9403	306	413.80	deposit	2023-01-17
9404	820	298.30	deposit	2023-08-17
9405	689	167.90	withdrawal	2024-05-12
9406	1385	403.20	withdrawal	2023-10-14
9407	816	138.00	withdrawal	2023-02-15
9408	465	449.40	deposit	2024-05-19
9409	135	304.90	withdrawal	2024-01-02
9410	1740	268.20	deposit	2024-01-31
9411	115	266.30	deposit	2023-04-07
9412	233	348.90	withdrawal	2024-05-31
9413	656	433.30	withdrawal	2023-05-04
9414	668	239.90	withdrawal	2024-01-15
9415	1538	497.60	withdrawal	2024-01-02
9416	884	138.40	deposit	2023-03-25
9417	15	443.80	deposit	2024-04-20
9418	263	311.70	deposit	2024-03-13
9419	936	165.20	withdrawal	2023-04-29
9420	100	473.70	deposit	2024-04-21
9421	1090	265.10	deposit	2024-01-22
9422	1482	493.90	deposit	2023-09-09
9423	1783	330.00	withdrawal	2023-11-08
9424	817	132.80	deposit	2023-04-16
9425	453	112.30	withdrawal	2024-02-05
9426	453	344.00	withdrawal	2023-05-13
9427	1113	254.70	deposit	2023-05-27
9428	187	482.70	withdrawal	2023-08-14
9429	627	71.60	deposit	2023-06-22
9430	1380	338.40	deposit	2023-09-29
9431	269	426.00	deposit	2023-09-22
9432	669	277.00	withdrawal	2023-03-13
9433	1077	217.30	withdrawal	2023-03-08
9434	1019	438.00	deposit	2023-10-01
9435	865	390.80	withdrawal	2023-01-23
9436	984	280.40	deposit	2023-09-29
9437	414	49.60	withdrawal	2024-02-17
9438	1581	227.70	withdrawal	2024-04-25
9439	523	471.50	withdrawal	2024-02-26
9440	764	244.70	withdrawal	2023-07-30
9441	1231	258.50	withdrawal	2023-03-05
9442	1187	418.30	deposit	2024-04-19
9443	802	459.90	withdrawal	2023-02-27
9444	169	373.50	withdrawal	2023-06-30
9445	1682	28.70	deposit	2023-01-13
9446	1100	133.60	deposit	2024-01-25
9447	28	261.20	withdrawal	2024-04-23
9448	596	324.70	withdrawal	2023-04-05
9449	730	245.80	withdrawal	2023-08-15
9450	1021	249.50	withdrawal	2024-01-05
9451	1164	364.30	deposit	2023-08-26
9452	1642	206.70	deposit	2023-04-08
9453	1104	35.50	withdrawal	2023-01-25
9454	112	500.20	withdrawal	2023-07-02
9455	1088	25.30	deposit	2023-06-28
9456	615	229.20	withdrawal	2023-09-06
9457	64	317.50	withdrawal	2023-09-14
9458	843	409.70	withdrawal	2023-11-27
9459	1413	100.50	withdrawal	2023-06-27
9460	1033	446.90	withdrawal	2023-12-15
9461	1276	464.80	deposit	2023-09-25
9462	9	242.20	withdrawal	2023-07-20
9463	1523	440.10	withdrawal	2023-06-16
9464	1777	232.10	deposit	2024-01-20
9465	72	139.20	withdrawal	2024-03-28
9466	1329	289.30	withdrawal	2023-07-11
9467	978	159.80	withdrawal	2023-12-09
9468	1188	34.10	withdrawal	2024-04-09
9469	767	417.90	deposit	2023-09-07
9470	901	293.60	withdrawal	2023-04-03
9471	844	356.50	deposit	2023-11-27
9472	988	122.10	withdrawal	2024-02-02
9473	673	498.50	deposit	2024-02-07
9474	270	304.40	deposit	2024-02-18
9475	71	280.80	deposit	2023-06-15
9476	490	399.90	withdrawal	2023-03-08
9477	590	348.50	withdrawal	2023-08-07
9478	871	261.10	withdrawal	2023-08-07
9479	649	84.00	withdrawal	2024-01-27
9480	170	26.40	withdrawal	2023-10-25
9481	239	123.50	deposit	2024-01-21
9482	1795	290.80	deposit	2023-08-22
9483	695	413.80	withdrawal	2024-01-18
9484	1281	324.30	withdrawal	2024-03-16
9485	298	241.80	withdrawal	2023-11-09
9486	1019	435.30	deposit	2024-02-15
9487	1377	48.90	withdrawal	2023-07-10
9488	1425	229.20	withdrawal	2023-11-03
9489	625	456.50	deposit	2023-01-20
9490	915	312.50	deposit	2023-12-18
9491	1111	219.40	deposit	2024-05-27
9492	1264	70.00	withdrawal	2023-08-16
9493	1350	60.40	withdrawal	2023-12-24
9494	814	339.10	withdrawal	2024-05-24
9495	1540	371.80	deposit	2023-12-08
9496	1107	67.60	withdrawal	2023-02-05
9497	1261	87.40	deposit	2023-03-21
9498	1744	235.80	deposit	2023-06-13
9499	1508	44.10	deposit	2023-09-28
9500	930	413.70	deposit	2023-10-26
9501	1691	149.80	withdrawal	2023-02-15
9502	145	435.10	withdrawal	2024-05-27
9503	152	19.50	deposit	2023-01-16
9504	966	486.70	withdrawal	2023-10-16
9505	1212	8.10	deposit	2024-01-11
9506	720	200.20	withdrawal	2024-04-22
9507	1662	87.20	deposit	2023-04-16
9508	212	259.00	deposit	2023-04-17
9509	1173	476.40	deposit	2024-03-09
9510	1405	413.10	withdrawal	2023-01-27
9511	1233	144.70	deposit	2023-12-13
9512	215	278.80	deposit	2023-12-02
9513	336	161.60	deposit	2023-06-26
9514	719	210.90	deposit	2023-04-20
9515	578	150.10	withdrawal	2023-11-26
9516	946	375.00	withdrawal	2023-05-03
9517	984	367.40	deposit	2024-02-03
9518	921	395.60	deposit	2023-10-23
9519	1701	494.20	withdrawal	2023-11-10
9520	1636	328.90	withdrawal	2023-12-23
9521	1477	115.50	deposit	2023-02-14
9522	556	499.90	deposit	2023-11-06
9523	106	128.80	deposit	2023-12-20
9524	823	255.10	withdrawal	2023-09-09
9525	56	230.40	withdrawal	2023-11-28
9526	315	475.40	withdrawal	2023-05-23
9527	913	460.10	deposit	2023-11-16
9528	1018	219.40	withdrawal	2024-03-30
9529	1650	388.10	withdrawal	2023-06-21
9530	945	52.10	withdrawal	2023-04-20
9531	452	20.20	deposit	2023-08-31
9532	524	406.90	withdrawal	2023-08-03
9533	1729	220.10	withdrawal	2024-05-07
9534	1198	141.90	withdrawal	2024-02-16
9535	265	252.90	deposit	2023-05-27
9536	1326	437.50	deposit	2023-01-16
9537	1797	63.70	withdrawal	2024-05-11
9538	470	293.40	deposit	2023-12-16
9539	467	282.40	deposit	2023-08-19
9540	1194	24.20	deposit	2023-09-23
9541	563	431.90	deposit	2024-03-23
9542	88	229.40	withdrawal	2024-03-29
9543	709	236.50	deposit	2023-03-06
9544	541	414.20	deposit	2024-01-01
9545	1780	163.80	withdrawal	2023-10-20
9546	1094	19.80	withdrawal	2023-01-14
9547	304	103.30	withdrawal	2024-05-11
9548	1715	70.20	withdrawal	2023-06-13
9549	684	110.80	deposit	2024-03-20
9550	219	72.50	withdrawal	2023-08-25
9551	1552	236.00	deposit	2023-11-25
9552	1773	214.70	deposit	2023-07-05
9553	1369	67.80	deposit	2024-05-24
9554	1411	398.00	deposit	2023-05-22
9555	183	176.70	deposit	2023-08-23
9556	45	240.10	deposit	2023-08-14
9557	1357	327.20	deposit	2023-05-30
9558	1770	71.60	withdrawal	2023-04-02
9559	1686	102.20	withdrawal	2023-09-30
9560	1514	201.50	withdrawal	2024-04-26
9561	64	447.20	deposit	2023-06-05
9562	1156	142.80	withdrawal	2024-04-01
9563	169	211.10	withdrawal	2023-04-23
9564	858	85.40	withdrawal	2023-01-24
9565	1681	448.50	withdrawal	2023-09-13
9566	376	448.20	deposit	2024-04-20
9567	905	5.10	withdrawal	2023-04-01
9568	1598	391.90	withdrawal	2023-05-17
9569	1453	175.30	withdrawal	2023-06-22
9570	1792	37.20	deposit	2023-06-25
9571	1368	99.50	withdrawal	2023-08-05
9572	110	443.70	withdrawal	2024-03-02
9573	1396	359.10	withdrawal	2023-08-11
9574	652	437.70	withdrawal	2024-01-30
9575	1275	242.30	withdrawal	2023-04-22
9576	655	213.70	deposit	2024-01-10
9577	1243	140.70	withdrawal	2024-02-13
9578	1519	302.60	withdrawal	2023-04-29
9579	970	147.80	withdrawal	2024-01-16
9580	709	325.80	deposit	2024-04-12
9581	485	345.80	deposit	2023-07-15
9582	482	450.20	withdrawal	2024-01-23
9583	350	391.60	deposit	2023-06-13
9584	1196	278.30	withdrawal	2023-07-17
9585	623	438.70	withdrawal	2024-05-13
9586	1611	341.70	withdrawal	2023-09-13
9587	250	285.50	deposit	2023-08-18
9588	1310	134.60	deposit	2024-03-22
9589	721	58.20	deposit	2024-01-09
9590	1028	8.80	withdrawal	2023-03-20
9591	1294	415.30	deposit	2024-03-13
9592	1513	148.90	withdrawal	2023-06-16
9593	1022	417.50	deposit	2023-08-01
9594	55	453.40	withdrawal	2023-01-24
9595	649	55.50	deposit	2023-12-30
9596	1302	444.60	deposit	2024-01-06
9597	919	281.60	deposit	2023-03-18
9598	3	219.60	withdrawal	2023-07-26
9599	372	449.30	deposit	2023-03-05
9600	1525	236.80	withdrawal	2023-12-20
9601	672	494.60	deposit	2023-04-14
9602	222	182.60	deposit	2023-01-26
9603	594	234.30	deposit	2023-06-21
9604	305	388.40	withdrawal	2023-02-18
9605	1572	342.80	deposit	2023-02-19
9606	1245	173.30	withdrawal	2023-10-01
9607	551	464.50	withdrawal	2023-10-27
9608	1059	461.00	withdrawal	2023-05-11
9609	490	187.00	deposit	2024-02-26
9610	42	127.80	deposit	2023-06-10
9611	150	245.80	withdrawal	2023-04-18
9612	1020	307.60	withdrawal	2023-06-30
9613	421	408.80	deposit	2023-08-17
9614	775	169.60	withdrawal	2024-02-26
9615	1368	255.60	deposit	2023-05-20
9616	775	32.90	withdrawal	2023-11-04
9617	136	364.30	withdrawal	2024-02-22
9618	36	373.10	withdrawal	2023-07-15
9619	912	477.70	deposit	2024-04-26
9620	175	129.00	deposit	2024-01-24
9621	1312	289.10	deposit	2024-02-09
9622	767	53.70	withdrawal	2024-01-18
9623	510	355.50	withdrawal	2024-04-07
9624	619	172.60	deposit	2024-05-12
9625	1640	483.30	withdrawal	2024-01-02
9626	1412	235.90	withdrawal	2023-08-13
9627	525	253.10	deposit	2023-04-12
9628	514	333.10	deposit	2023-02-09
9629	293	51.30	withdrawal	2024-04-02
9630	306	255.10	withdrawal	2023-04-17
9631	360	419.70	withdrawal	2023-09-21
9632	1186	456.20	deposit	2023-11-20
9633	978	199.00	deposit	2024-02-19
9634	1423	57.60	deposit	2024-02-29
9635	1328	57.10	withdrawal	2023-09-11
9636	550	406.30	deposit	2023-07-09
9637	1165	203.90	withdrawal	2023-08-16
9638	837	347.10	withdrawal	2024-05-26
9639	1682	67.90	deposit	2024-04-13
9640	720	12.40	deposit	2023-05-27
9641	153	335.80	withdrawal	2023-06-07
9642	939	82.40	withdrawal	2024-05-10
9643	1728	8.50	withdrawal	2023-11-12
9644	1267	142.20	withdrawal	2024-05-28
9645	52	45.90	withdrawal	2024-05-15
9646	239	215.40	withdrawal	2023-09-05
9647	257	45.60	withdrawal	2023-12-13
9648	1137	91.50	withdrawal	2023-12-28
9649	725	387.70	withdrawal	2024-03-06
9650	1498	165.60	deposit	2024-04-29
9651	1062	234.20	withdrawal	2023-04-01
9652	1075	351.10	deposit	2023-04-29
9653	1764	231.00	withdrawal	2023-09-27
9654	1500	157.20	deposit	2023-12-13
9655	581	440.80	deposit	2023-07-06
9656	517	323.60	withdrawal	2023-02-12
9657	456	205.70	deposit	2023-06-03
9658	1787	216.80	withdrawal	2024-04-07
9659	1130	85.90	deposit	2023-03-24
9660	751	86.80	deposit	2023-03-04
9661	1000	480.90	deposit	2023-02-08
9662	109	189.10	deposit	2023-03-26
9663	362	297.20	deposit	2024-03-03
9664	1707	133.70	deposit	2024-03-17
9665	491	55.30	withdrawal	2023-08-26
9666	1484	111.00	withdrawal	2024-05-29
9667	743	432.90	deposit	2024-02-10
9668	1767	308.90	withdrawal	2023-08-01
9669	825	415.10	deposit	2023-12-11
9670	49	147.40	withdrawal	2023-10-25
9671	287	497.10	deposit	2023-04-25
9672	708	36.20	deposit	2023-11-09
9673	1284	285.60	withdrawal	2023-07-15
9674	1204	39.70	deposit	2023-02-14
9675	956	262.20	withdrawal	2023-05-06
9676	1576	110.90	withdrawal	2023-01-04
9677	781	270.50	deposit	2024-04-09
9678	285	479.90	withdrawal	2023-11-21
9679	952	334.20	withdrawal	2023-12-06
9680	691	301.00	deposit	2023-01-30
9681	528	462.50	withdrawal	2024-01-15
9682	107	16.90	deposit	2023-06-05
9683	198	109.90	deposit	2023-05-08
9684	1358	217.80	withdrawal	2023-12-24
9685	352	249.60	withdrawal	2023-04-13
9686	1452	279.00	deposit	2023-12-28
9687	850	192.00	deposit	2024-05-07
9688	979	173.80	withdrawal	2024-05-19
9689	1515	451.20	deposit	2023-07-15
9690	601	469.90	withdrawal	2024-03-10
9691	557	212.60	deposit	2024-05-14
9692	743	200.70	deposit	2023-03-20
9693	1091	144.00	deposit	2024-02-28
9694	715	335.30	deposit	2024-01-25
9695	496	56.00	withdrawal	2023-03-26
9696	109	171.70	deposit	2023-02-26
9697	137	206.80	deposit	2023-08-23
9698	48	249.10	withdrawal	2024-05-19
9699	1342	239.80	withdrawal	2023-09-06
9700	87	398.00	deposit	2023-09-22
9701	135	238.50	deposit	2023-04-17
9702	1749	320.20	deposit	2023-02-24
9703	1294	210.30	deposit	2023-07-23
9704	187	74.40	withdrawal	2023-06-11
9705	1579	346.70	deposit	2024-04-03
9706	649	55.00	deposit	2023-11-28
9707	1086	449.90	deposit	2023-12-10
9708	1678	96.80	withdrawal	2023-09-04
9709	927	413.40	withdrawal	2023-10-15
9710	769	272.70	deposit	2023-06-04
9711	1114	88.70	withdrawal	2023-04-13
9712	599	296.50	deposit	2024-05-27
9713	249	463.40	deposit	2023-05-17
9714	722	317.50	withdrawal	2023-08-20
9715	1129	417.00	withdrawal	2023-12-16
9716	1578	272.10	withdrawal	2023-02-20
9717	683	23.30	withdrawal	2023-06-19
9718	1727	324.40	withdrawal	2023-04-02
9719	778	373.70	deposit	2023-11-14
9720	391	491.00	deposit	2023-01-11
9721	1151	282.50	deposit	2023-04-21
9722	1056	368.50	withdrawal	2023-08-05
9723	185	210.60	withdrawal	2024-04-28
9724	1310	308.50	deposit	2023-09-11
9725	416	268.10	withdrawal	2024-02-10
9726	711	11.80	withdrawal	2024-01-02
9727	1203	153.40	deposit	2023-10-08
9728	497	305.40	deposit	2023-12-26
9729	1364	160.00	withdrawal	2023-12-19
9730	247	146.80	withdrawal	2023-11-16
9731	1056	483.20	deposit	2023-02-16
9732	1422	212.20	deposit	2024-04-01
9733	384	457.60	deposit	2024-03-25
9734	158	186.50	withdrawal	2024-02-25
9735	1157	200.80	deposit	2024-01-10
9736	686	44.30	deposit	2023-09-27
9737	217	303.60	withdrawal	2024-04-16
9738	395	448.50	deposit	2024-02-10
9739	1381	53.60	withdrawal	2024-04-14
9740	691	278.70	deposit	2023-03-10
9741	792	476.10	withdrawal	2024-03-20
9742	1763	231.30	withdrawal	2023-02-14
9743	1034	215.90	withdrawal	2023-03-29
9744	1772	426.00	deposit	2023-05-12
9745	55	454.30	withdrawal	2024-01-02
9746	1540	295.80	deposit	2024-02-02
9747	1304	123.70	withdrawal	2024-01-30
9748	126	150.40	withdrawal	2023-08-10
9749	823	56.80	deposit	2024-03-27
9750	1110	408.20	withdrawal	2023-05-07
9751	1447	411.60	withdrawal	2023-07-28
9752	208	183.80	withdrawal	2024-01-27
9753	1110	467.80	deposit	2024-01-12
9754	997	134.70	deposit	2023-07-07
9755	969	461.30	withdrawal	2024-04-27
9756	1229	287.50	deposit	2024-03-20
9757	698	307.10	deposit	2024-05-05
9758	1115	231.20	withdrawal	2023-03-04
9759	1768	390.50	deposit	2023-11-11
9760	459	489.50	deposit	2024-03-03
9761	1269	348.80	withdrawal	2023-04-25
9762	766	374.50	deposit	2023-07-27
9763	577	464.00	deposit	2023-04-21
9764	1530	198.10	deposit	2023-08-06
9765	783	27.30	deposit	2023-03-25
9766	18	25.30	deposit	2023-10-10
9767	1698	408.90	withdrawal	2023-04-15
9768	527	280.70	withdrawal	2024-03-22
9769	377	55.00	withdrawal	2023-09-09
9770	7	122.00	withdrawal	2023-04-17
9771	554	229.70	deposit	2023-03-04
9772	109	167.90	withdrawal	2024-02-11
9773	1324	249.90	withdrawal	2023-04-19
9774	796	29.60	deposit	2023-08-19
9775	538	176.00	withdrawal	2023-05-17
9776	412	234.40	deposit	2023-05-30
9777	183	196.50	deposit	2023-10-30
9778	150	383.30	deposit	2023-02-19
9779	894	116.60	deposit	2023-11-27
9780	1672	291.70	withdrawal	2023-01-31
9781	32	359.50	withdrawal	2024-05-12
9782	22	447.00	deposit	2023-08-11
9783	952	457.10	withdrawal	2023-04-06
9784	1100	110.70	withdrawal	2023-07-03
9785	991	185.90	deposit	2023-11-03
9786	1707	211.60	withdrawal	2024-03-30
9787	492	412.30	withdrawal	2023-09-15
9788	720	235.60	deposit	2023-09-08
9789	1478	452.30	deposit	2023-10-21
9790	1352	45.00	withdrawal	2023-10-26
9791	1146	49.10	deposit	2023-01-22
9792	981	488.40	deposit	2024-02-27
9793	1444	228.40	withdrawal	2024-04-10
9794	144	183.20	withdrawal	2023-03-26
9795	274	227.00	deposit	2024-04-28
9796	762	140.50	withdrawal	2023-01-03
9797	209	380.20	deposit	2023-12-18
9798	456	23.30	withdrawal	2024-05-13
9799	820	145.90	withdrawal	2023-01-04
9800	685	350.50	deposit	2023-02-12
9801	391	459.90	withdrawal	2023-09-12
9802	1091	155.40	deposit	2023-05-10
9803	1372	247.20	deposit	2023-06-25
9804	315	242.80	deposit	2023-01-25
9805	919	284.00	deposit	2023-07-03
9806	402	453.90	withdrawal	2024-05-25
9807	1240	440.20	deposit	2024-03-05
9808	1123	174.30	deposit	2023-10-13
9809	1618	163.60	withdrawal	2023-06-20
9810	1743	226.20	withdrawal	2023-01-11
9811	389	451.00	withdrawal	2023-12-13
9812	282	406.50	deposit	2023-01-16
9813	563	33.90	withdrawal	2024-01-09
9814	1601	116.60	deposit	2024-04-11
9815	1683	439.70	deposit	2023-08-19
9816	909	76.60	withdrawal	2024-02-03
9817	973	22.20	deposit	2023-05-20
9818	156	212.70	deposit	2023-11-27
9819	1341	75.10	deposit	2024-01-05
9820	39	484.00	deposit	2023-07-13
9821	1373	285.50	withdrawal	2024-01-01
9822	643	307.50	deposit	2023-07-20
9823	883	494.90	withdrawal	2023-09-18
9824	659	364.80	withdrawal	2024-03-13
9825	739	234.00	deposit	2023-05-13
9826	507	133.60	withdrawal	2024-02-23
9827	507	326.90	withdrawal	2023-04-14
9828	461	149.30	withdrawal	2023-03-07
9829	1624	357.90	deposit	2023-03-09
9830	26	43.40	withdrawal	2023-11-10
9831	1616	212.60	withdrawal	2024-03-27
9832	877	320.60	withdrawal	2023-02-04
9833	1322	473.80	withdrawal	2024-03-12
9834	562	144.70	deposit	2023-10-30
9835	929	151.30	deposit	2023-01-10
9836	1619	325.70	deposit	2024-03-14
9837	1559	39.40	withdrawal	2023-07-14
9838	1737	425.40	deposit	2023-08-27
9839	1367	291.40	deposit	2023-08-15
9840	440	138.70	deposit	2024-03-28
9841	250	229.70	deposit	2023-09-14
9842	601	106.90	withdrawal	2023-03-20
9843	30	309.20	deposit	2023-08-31
9844	176	234.40	deposit	2023-03-08
9845	178	258.80	deposit	2024-02-09
9846	133	225.20	withdrawal	2024-04-18
9847	1609	327.40	deposit	2023-09-24
9848	1446	311.80	deposit	2023-10-03
9849	488	221.90	withdrawal	2024-04-15
9850	1445	220.10	withdrawal	2024-01-27
9851	357	295.00	deposit	2023-05-12
9852	1537	123.90	deposit	2024-05-15
9853	1605	9.20	deposit	2023-07-31
9854	209	145.70	deposit	2024-03-16
9855	669	444.40	deposit	2023-06-09
9856	238	190.90	deposit	2024-05-14
9857	1533	476.30	withdrawal	2024-03-30
9858	1185	401.20	withdrawal	2023-01-21
9859	708	458.10	deposit	2024-01-04
9860	1165	40.50	deposit	2023-01-29
9861	1080	390.90	withdrawal	2023-12-27
9862	665	438.50	deposit	2023-10-11
9863	890	380.40	deposit	2023-11-30
9864	1093	48.70	deposit	2024-05-27
9865	996	220.60	withdrawal	2024-02-16
9866	121	494.20	withdrawal	2023-04-11
9867	1600	53.10	deposit	2023-12-14
9868	719	253.80	withdrawal	2023-11-29
9869	1490	122.40	deposit	2023-07-17
9870	235	234.90	withdrawal	2023-06-25
9871	960	212.10	withdrawal	2024-05-22
9872	817	330.70	deposit	2023-10-23
9873	1323	123.00	deposit	2023-05-14
9874	211	335.10	withdrawal	2023-01-15
9875	1490	338.50	withdrawal	2023-07-30
9876	308	166.20	deposit	2024-05-01
9877	1475	447.70	deposit	2023-03-04
9878	942	201.30	deposit	2024-02-21
9879	581	250.40	withdrawal	2023-08-17
9880	1703	150.40	withdrawal	2024-04-27
9881	1159	212.50	withdrawal	2024-05-30
9882	1432	430.40	withdrawal	2024-03-08
9883	286	483.80	deposit	2023-10-07
9884	1048	144.00	withdrawal	2023-05-28
9885	853	253.10	deposit	2023-01-31
9886	1456	420.70	deposit	2023-08-27
9887	1699	73.90	withdrawal	2024-03-20
9888	585	222.60	deposit	2023-11-23
9889	449	497.70	withdrawal	2023-01-18
9890	1297	101.00	deposit	2024-02-28
9891	848	155.70	deposit	2024-05-13
9892	1077	460.20	withdrawal	2023-11-28
9893	1367	274.20	withdrawal	2023-08-17
9894	356	6.70	deposit	2023-11-10
9895	1588	72.00	deposit	2023-03-12
9896	1082	310.40	withdrawal	2023-11-14
9897	1256	67.90	withdrawal	2023-08-01
9898	210	153.60	deposit	2024-03-24
9899	604	378.50	deposit	2023-01-25
9900	401	452.30	deposit	2024-05-25
9901	573	443.00	withdrawal	2023-10-03
9902	1714	343.80	withdrawal	2023-08-25
9903	1017	336.90	deposit	2023-08-15
9904	1218	402.80	withdrawal	2023-12-07
9905	98	191.00	withdrawal	2023-03-14
9906	1570	383.90	withdrawal	2024-04-10
9907	1270	364.10	withdrawal	2023-03-09
9908	32	325.20	withdrawal	2024-01-04
9909	1720	226.60	deposit	2024-05-28
9910	1353	79.90	deposit	2023-11-30
9911	233	101.70	deposit	2023-05-27
9912	967	80.60	withdrawal	2023-06-06
9913	200	414.10	deposit	2023-02-09
9914	348	251.60	withdrawal	2023-11-01
9915	125	288.10	deposit	2023-06-05
9916	1508	283.60	deposit	2023-08-08
9917	325	189.90	deposit	2024-03-07
9918	1538	453.60	withdrawal	2024-01-09
9919	1275	103.20	withdrawal	2023-09-02
9920	170	130.90	deposit	2023-06-12
9921	1013	422.00	withdrawal	2023-01-31
9922	199	209.20	withdrawal	2023-06-20
9923	1599	436.60	deposit	2024-02-09
9924	136	22.90	withdrawal	2023-03-09
9925	1368	91.90	deposit	2023-03-16
9926	842	261.10	withdrawal	2023-04-22
9927	399	187.10	deposit	2023-01-14
9928	448	41.40	withdrawal	2024-02-07
9929	372	96.00	withdrawal	2024-05-26
9930	763	201.30	withdrawal	2023-07-01
9931	1552	408.30	deposit	2023-08-12
9932	1475	190.60	deposit	2023-03-15
9933	786	170.80	withdrawal	2023-09-22
9934	225	427.80	deposit	2023-07-18
9935	567	478.00	withdrawal	2023-08-03
9936	655	275.80	deposit	2023-12-15
9937	549	208.20	withdrawal	2024-01-10
9938	212	205.70	deposit	2024-05-03
9939	1500	282.50	deposit	2023-09-02
9940	395	421.20	withdrawal	2023-01-31
9941	1010	189.40	deposit	2023-05-22
9942	739	317.50	deposit	2023-06-20
9943	955	34.70	withdrawal	2023-12-12
9944	1151	237.40	withdrawal	2023-04-19
9945	1582	447.60	deposit	2023-11-02
9946	1148	433.50	withdrawal	2024-05-14
9947	430	126.90	withdrawal	2023-11-06
9948	1462	336.60	withdrawal	2023-10-26
9949	1792	333.20	withdrawal	2023-11-20
9950	1513	435.30	deposit	2024-05-28
9951	1626	471.90	deposit	2024-03-28
9952	927	335.10	deposit	2023-06-15
9953	259	156.30	deposit	2023-01-31
9954	1690	289.60	withdrawal	2023-02-16
9955	1234	8.30	withdrawal	2024-03-01
9956	1140	395.50	withdrawal	2023-12-13
9957	187	250.10	withdrawal	2023-03-06
9958	1276	244.70	deposit	2023-04-25
9959	1087	51.70	withdrawal	2023-12-05
9960	658	257.00	deposit	2024-03-06
9961	125	363.40	deposit	2023-08-22
9962	889	216.20	deposit	2023-02-23
9963	366	325.10	withdrawal	2023-03-02
9964	343	339.10	withdrawal	2024-05-30
9965	1046	290.30	withdrawal	2023-02-21
9966	1548	151.60	deposit	2024-05-09
9967	1051	40.70	deposit	2024-03-20
9968	1362	370.60	withdrawal	2023-07-04
9969	714	226.30	deposit	2023-05-28
9970	1510	324.40	deposit	2023-07-23
9971	1381	47.90	withdrawal	2023-02-07
9972	784	286.50	deposit	2024-01-11
9973	1605	319.00	deposit	2023-01-06
9974	567	236.70	withdrawal	2024-05-27
9975	1164	487.10	withdrawal	2023-02-08
9976	834	327.90	deposit	2024-01-30
9977	775	60.90	deposit	2023-12-25
9978	1679	423.60	deposit	2024-01-14
9979	864	467.20	withdrawal	2023-08-27
9980	403	147.50	withdrawal	2024-01-05
9981	1268	19.10	deposit	2024-04-29
9982	1310	396.50	deposit	2023-11-08
9983	619	368.00	withdrawal	2023-02-25
9984	137	188.80	deposit	2023-12-15
9985	143	331.80	deposit	2023-04-03
9986	1595	165.40	withdrawal	2023-11-13
9987	1012	133.50	withdrawal	2024-01-21
9988	129	388.00	deposit	2024-02-11
9989	1587	37.70	withdrawal	2024-05-10
9990	358	144.40	withdrawal	2023-12-05
9991	658	267.80	deposit	2023-08-03
9992	1044	272.10	deposit	2023-06-12
9993	1110	243.50	withdrawal	2023-11-30
9994	59	441.60	withdrawal	2023-01-12
9995	1350	233.30	deposit	2024-02-09
9996	1407	128.10	withdrawal	2023-02-25
9997	830	252.60	withdrawal	2024-01-22
9998	903	52.70	withdrawal	2023-03-27
9999	1590	91.00	deposit	2023-05-10
10000	1776	137.40	withdrawal	2023-01-29
\.


--
-- TOC entry 2050 (class 0 OID 0)
-- Dependencies: 178
-- Name: transactions_transactionid_seq; Type: SEQUENCE SET; Schema: main; Owner: postgres
--

SELECT pg_catalog.setval('main.transactions_transactionid_seq', 1, false);


--
-- TOC entry 1918 (class 2606 OID 16444)
-- Name: accounts_pkey; Type: CONSTRAINT; Schema: main; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY main.accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (accountid);


--
-- TOC entry 1916 (class 2606 OID 16436)
-- Name: beneficiaries_pkey; Type: CONSTRAINT; Schema: main; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY main.beneficiaries
    ADD CONSTRAINT beneficiaries_pkey PRIMARY KEY (beneficiaryid);


--
-- TOC entry 1922 (class 2606 OID 16460)
-- Name: transactions_pkey; Type: CONSTRAINT; Schema: main; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY main.transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (transactionid);


--
-- TOC entry 1919 (class 1259 OID 16450)
-- Name: idx_accounts_beneficiaryid; Type: INDEX; Schema: main; Owner: postgres; Tablespace: 
--

CREATE INDEX idx_accounts_beneficiaryid ON main.accounts USING btree (beneficiaryid);


--
-- TOC entry 1920 (class 1259 OID 16466)
-- Name: idx_transactions_accountid; Type: INDEX; Schema: main; Owner: postgres; Tablespace: 
--

CREATE INDEX idx_transactions_accountid ON main.transactions USING btree (accountid);


--
-- TOC entry 1923 (class 2606 OID 16445)
-- Name: accben_fkey; Type: FK CONSTRAINT; Schema: main; Owner: postgres
--

ALTER TABLE ONLY main.accounts
    ADD CONSTRAINT accben_fkey FOREIGN KEY (beneficiaryid) REFERENCES main.beneficiaries(beneficiaryid) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 1924 (class 2606 OID 16461)
-- Name: transacc_fkey; Type: FK CONSTRAINT; Schema: main; Owner: postgres
--

ALTER TABLE ONLY main.transactions
    ADD CONSTRAINT transacc_fkey FOREIGN KEY (accountid) REFERENCES main.accounts(accountid) ON UPDATE CASCADE ON DELETE CASCADE;


-- Completed on 2024-12-07 20:45:43

--
-- PostgreSQL database dump complete
--

