const satelliteXml = '''
<satellites>
       <satellite name="no sat" startDate=""></satellite>
       <satellite name="AISAT1" startDate="2019-04-07">AISAT-1 AMSAT India APRS Digipeater</satellite>
       <satellite name="AO-7" startDate="1974-11-15">AMSAT-OSCAR 7</satellite>
       <satellite name="AO-85" startDate="2015-10-09">AMSAT-OSCAR 85 (Fox-1A)</satellite>
       <satellite name="AO-91" startDate="2017-11-23">AMSAT-OSCAR 91 (RadFxSat / Fox-1B)</satellite>
       <satellite name="AO-92" startDate="2018-01-12">AMSAT-OSCAR 92 (Fox-1D)</satellite>
       <satellite name="BO-102" startDate="2019-07-25">BIT Progress-OSCAR 102 (CAS-7B)</satellite>
       <satellite endDate="2017-02-17" name="BY70-1" startDate="2016-12-28">Bayi Kepu Weixing 1</satellite>
       <satellite name="CAS-2T" startDate="2016-11-09">CAS-2T</satellite>
       <satellite name="CAS-3H" startDate="2015-09-18">LilacSat-2</satellite>
       <satellite name="CAS-4A" startDate="2017-10-18">CAMSAT 4A (CAS-4A)</satellite>
       <satellite name="CAS-4B" startDate="2017-10-18">CAMSAT 4B (CAS-4B)</satellite>
       <satellite name="DO-64" startDate="2008-04-28">Delfi OSCAR-64</satellite>
       <satellite name="EO-79" startDate="2014-06-19">FUNcube-3</satellite>
       <satellite name="EO-88" startDate="2017-02-15">Emirates-OSCAR 88 (Nayif-1)</satellite>
       <satellite name="FO-118" startDate="2022-12-09">CAS-5A</satellite>
       <satellite endDate="1989-11-05" name="FO-12" startDate="1986-08-12">Fuji-OSCAR 12</satellite>
       <satellite name="FO-20" startDate="1990-02-07">Fuji-OSCAR 20</satellite>
       <satellite name="FO-29" startDate="1996-07-17">Fuji-OSCAR 29</satellite>
       <satellite name="FO-99" startDate="2019-01-26">Fuji-OSCAR 99 (NEXUS)</satellite>
       <satellite name="FS-3" startDate="2017-09-24">FalconSAT 3</satellite>
       <satellite name="HO-107" startDate="2020-05-10">HuskySat OSCAR 107</satellite>
       <satellite name="HO-113" startDate="2021-12-26">HO-113</satellite>
       <satellite name="HO-119" startDate="2022-12-18">Hope-OSCAR 119</satellite>
       <satellite name="HO-68" startDate="2009-12-15">Hope-Oscar 68</satellite>
       <satellite name="INSPR7" startDate="2023-04-15">INSPIRE-Sat7</satellite>
       <satellite name="IO-117" startDate="2022-07-13">GreenCube</satellite>
       <satellite name="IO-86" startDate="2015-09-28">Indonesia-OSCAR 86 (LAPAN-ORARI)</satellite>
       <satellite name="JO-97" startDate="2018-12-08">Jordan-OSCAR 97(JY1Sat)</satellite>
       <satellite endDate="2012-01-04" name="KEDR" startDate="2011-08-03">ARISSat-1</satellite>
       <satellite name="LEDSAT" startDate="2021-08-17">LEDSAT</satellite>
       <satellite name="LO-19" startDate="1990-01-22">Lusat-OSCAR 19</satellite>
       <satellite endDate="2014-07-28" name="LO-78" startDate="2014-04-22">LituanicaSAT-1</satellite>
       <satellite name="LO-87" startDate="2016-05-30">LUSEX-OSCAR 87</satellite>
       <satellite name="LO-90" startDate="2017-05-25">LilacSat-OSCAR 90 (LilacSat-1)</satellite>
       <satellite name="MAYA-3" startDate="2021-10-10">Cubesat</satellite>
       <satellite name="MAYA-4" startDate="2021-10-10">Cubesat</satellite>
       <satellite endDate="2000-06-16" name="MIREX" startDate="1991-02-01">MIR Packet Digipeater</satellite>
       <satellite name="MO-112" startDate="2021-06-22">Mirsat-1</satellite>
       <satellite name="NO-103" startDate="2019-06-25">Navy-OSCAR 103 (BRICSAT 2)</satellite>
       <satellite name="NO-104" startDate="2019-06-25">Navy-OSCAR 104 (PSAT 2)</satellite>
       <satellite name="NO-44" startDate="2001-09-30">Navy-OSCAR 44</satellite>
       <satellite name="NO-83" startDate="2015-05-20">BRICsat</satellite>
       <satellite name="NO-84" startDate="2015-05-20">PSAT</satellite>
       <satellite name="PO-101" startDate="2018-10-18">Phillipines-OSCAR-101 (Diwata-2)</satellite>
       <satellite name="QO-100" startDate="2019-02-02">Qatar-OSCAR 100 (Es&apos;hail-2/P4A)</satellite>
       <satellite endDate="1979-02-01" name="RS-1" startDate="1978-10-26">Radio Sputnik 1</satellite>
       <satellite endDate="2000-11-01" name="RS-10" startDate="1987-06-23">Radio Sputnik 10</satellite>
       <satellite endDate="2000-11-01" name="RS-11" startDate="1987-06-23">Radio Sputnik 11</satellite>
       <satellite endDate="2002-02-15" name="RS-12" startDate="1991-02-05">Radio Sputnik 12</satellite>
       <satellite endDate="2002-02-15" name="RS-13" startDate="1991-02-05">Radio Sputnik 13</satellite>
       <satellite name="RS-15" startDate="1994-12-16">Radio Sputnik 15</satellite>
       <satellite endDate="1979-02-01" name="RS-2" startDate="1978-10-26">Radio Sputnik 2</satellite>
       <satellite name="RS-44" startDate="2020-04-30">Radio Sputnik 44 (DOSAAF-85)</satellite>
       <satellite endDate="1987-05-10" name="RS-5" startDate="1981-12-17">Radio Sputnik 5</satellite>
       <satellite endDate="1984-12-09" name="RS-6" startDate="1981-12-17">Radio Sputnik 6</satellite>
       <satellite endDate="1987-06-01" name="RS-7" startDate="1981-12-18">Radio Sputnik 7</satellite>
       <satellite endDate="1985-12-16" name="RS-8" startDate="1981-12-17">Radio Sputnik 8</satellite>
       <satellite endDate="1999-07-28" name="SAREX" startDate="1990-12-02">Shuttle Amateur Radio Experiment (SAREX) Digipeater</satellite>
       <satellite name="SO-121" startDate="2023-11-11">Hades-D</satellite>
       <satellite endDate="2001-06-10" name="SO-35" startDate="1999-02-23">Sunsat-OSCAR 35</satellite>
       <satellite name="SO-41" startDate="2000-09-26">Saudi-OSCAR 41</satellite>
       <satellite name="SO-50" startDate="2002-12-20">Saudi-OSCAR 50</satellite>
       <satellite name="SO-67" startDate="2009-09-17">Sumbandila Oscar 67</satellite>
       <satellite name="TAURUS" startDate="2019-09-17">Taurus-1 (Jinniuzuo-1)</satellite>
       <satellite name="TEVEL1" startDate="2022-01-13">Tevel-1</satellite>
       <satellite name="TEVEL2" startDate="2022-01-13">Tevel-2</satellite>
       <satellite name="TEVEL3" startDate="2022-01-13">Tevel-3</satellite>
       <satellite name="TEVEL4" startDate="2022-01-13">Tevel-4</satellite>
       <satellite name="TEVEL5" startDate="2022-01-13">Tevel-5</satellite>
       <satellite name="TEVEL6" startDate="2022-01-13">Tevel-6</satellite>
       <satellite name="TEVEL7" startDate="2022-01-13">Tevel-7</satellite>
       <satellite name="TEVEL8" startDate="2022-01-13">Tevel-8</satellite>
       <satellite name="TO-108" startDate="2019-12-20">TQ-OSCAR 108 (CAS-6 / TQ-1)</satellite>
       <satellite name="UKUBE1" startDate="2016-06-01">UKube-1 (FUNcube-2)</satellite>
       <satellite name="UO-14" startDate="1990-01-22">UOSAT-OSCAR 14</satellite>
       <satellite name="UVSQ" startDate="2021-03-05">CubeSat</satellite>
       <satellite endDate="2014-07-11" name="VO-52" startDate="2005-05-05">VUsat-OSCAR 52</satellite>
       <satellite name="XW-2A" startDate="2015-09-18">Hope 2A (CAS-3A)</satellite>
       <satellite name="XW-2B" startDate="2015-09-18">Hope 2B (CAS-3B)</satellite>
       <satellite name="XW-2C" startDate="2015-09-18">Hope 2C (CAS-3C)</satellite>
       <satellite name="XW-2D" startDate="2015-09-18">Hope 2D (CAS-3D)</satellite>
       <satellite name="XW-2E" startDate="2015-09-18">Hope 2E (CAS-3E)</satellite>
       <satellite name="XW-2F" startDate="2015-09-18">Hope 2F (CAS-2F)</satellite>
     </satellites>''';

final List<String> satelliteList = [
  'no sat',
  'AISAT1',
  'AO-7',
  'AO-85',
  'AO-91',
  'AO-92',
  'BO-102',
  'CAS-2T',
  'CAS-3H',
  'CAS-4A',
  'CAS-4B',
  'DO-64',
  'EO-79',
  'EO-88',
  'FO-118',
  'FO-20',
  'FO-29',
  'FO-99',
  'FS-3',
  'HO-107',
  'HO-113',
  'HO-119',
  'HO-68',
  'INSPR7',
  'IO-117',
  'IO-86',
  'JO-97',
  'LEDSAT',
  'LO-19',
  'LO-87',
  'LO-90',
  'MAYA-3',
  'MAYA-4',
  'MO-112',
  'NO-103',
  'NO-104',
  'NO-44',
  'NO-83',
  'NO-84',
  'PO-101',
  'QO-100',
  'RS-15',
  'RS-44',
  'SO-121',
  'SO-41',
  'SO-50',
  'SO-67',
  'TAURUS',
  'TEVEL1',
  'TEVEL2',
  'TEVEL3',
  'TEVEL4',
  'TEVEL5',
  'TEVEL6',
  'TEVEL7',
  'TEVEL8',
  'TO-108',
  'UKUBE1',
  'UO-14',
  'UVSQ',
  'XW-2A',
  'XW-2B',
  'XW-2C',
  'XW-2D',
  'XW-2E',
  'XW-2F',
];
