
INSERT INTO econ_indicator
VALUES ('EUR-RFR', 'Euro Risk Free Rate', 'Euribor weekly until including 2019 and from 2020 on the €STR.');



INSERT INTO asset (symbol, currency, asset_name)
VALUES
('ACWI.PA', 'EUR', 'Lyxor MSCI All Country World UCITS ETF Acc'),
('BRNT.L', 'USD', 'WisdomTree Brent Crude Oil'),
('CMOD.L', 'USD', 'Invesco Bloomberg Commodity UCITS ETF'),
('CMOD.MI', 'EUR', 'Invesco Bloomberg Commodity UCITS ETF'),
('CORP.L', 'USD', 'iShares Global Corp Bond UCITS ETF USD (Dist)'),
('EBUL.MI', 'EUR', 'WisdomTree Gold - EUR Daily Hedged'),
('ELOW.MI', 'EUR', 'SPDR EURO STOXX Low Volatility UCITS ETF'),
('EMHD.SW', 'USD', 'Invesco FTSE Emerging Markets High Dividend Low Volatility UCITS ETF'),
('FXGD.AS', 'EUR', 'FinEx Physically Gold ETF (USD)'),
('GLRE.L', 'USD', 'SPDR Dow Jones Global Real Estate UCITS ETF'),
('LUTR.MI', 'EUR', 'SPDR Bloomberg Barclays 10+ Year U.S. Treasury Bond UCITS ETF'),
('TDIV.L', 'USD', 'VanEck Vectors Morningstar Developed Markets Dividend Leaders UCITS ETF'),
('WING.MI', 'EUR', 'iShares Fallen Angels High Yield Corp Bond UCITS ETF USD (Dist)'),
('X03F.F', 'EUR', 'Xtrackers II Eurozone Government Bond UCITS ETF 1D EUR'),
('XDGE.MI', 'EUR', 'Xtrackers (IE) Plc - Xtrackers USD Corporate Bond UCITS ETF 2D - EUR Hedged'),
('XGII.F', 'EUR', 'Xtrackers II Global Inflation-Linked Bond UCITS ETF 1D - EUR Hedged'),
('IWMO.L', 'USD', 'iShares Edge MSCI World Momentum Factor UCITS ETF'),
('PHAU.L', 'USD', 'WisdomTree Physical Gold'),
('DBZB.DE', 'EUR', 'Global Government Bond UCITS ETF 1C EUR Hedged');


INSERT INTO forex_pair
VALUES
('AUDUSD', 'AUD', 'USD'),
('AUDJPY', 'AUD', 'JPY'),
('AUDNZD', 'AUD', 'NZD'),
('AUDCAD', 'AUD', 'CAD'),
('AUDCHF', 'AUD', 'CHF'),
('CADJPY', 'CAD', 'JPY'),
('CADCHF', 'CAD', 'CHF'),
('CHFJPY', 'CHF', 'JPY'),
('EURNOK', 'EUR', 'NOK'),
('EURUSD', 'EUR', 'USD'),
('EURCHF', 'EUR', 'CHF'),
('EURTRY', 'EUR', 'TRY'),
('EURGBP', 'EUR', 'GBP'),
('EURJPY', 'EUR', 'JPY'),
('EURAUD', 'EUR', 'AUD'),
('EURCAD', 'EUR', 'CAD'),
('EURNZD', 'EUR', 'NZD'),
('EURSEK', 'EUR', 'SEK'),
('GBPJPY', 'GBP', 'JPY'),
('GBPNZD', 'GBP', 'NZD'),
('GBPAUD', 'GBP', 'AUD'),
('GBPCHF', 'GBP', 'CHF'),
('GBPUSD', 'GBP', 'USD'),
('GBPCAD', 'GBP', 'CAD'),
('NZDCHF', 'NZD', 'CHF'),
('NZDJPY', 'NZD', 'JPY'),
('NZDUSD', 'NZD', 'USD'),
('NZDCAD', 'NZD', 'CAD'),
('TRYJPY', 'TRY', 'JPY'),
('USDHKD', 'USD', 'HKD'),
('USDNOK', 'USD', 'NOK'),
('USDSEK', 'USD', 'SEK'),
('USDZAR', 'USD', 'ZAR'),
('USDMXN', 'USD', 'MXN'),
('USDTRY', 'USD', 'TRY'),
('USDCAD', 'USD', 'CAD'),
('USDCHF', 'USD', 'CHF'),
('USDJPY', 'USD', 'JPY'),
('USDCNH', 'USD', 'CNH'),
('ZARJPY', 'ZAR', 'JPY');

INSERT INTO currency
VALUES ('AFN', 'Afghan afghani', 'Afghanistan', 'Pul', 100),
('ALL', 'Albanian lek', 'Albania', 'Qintar', 100),
('DZD', 'Algerian dinar', 'Algeria', 'Santeem', 100),
('AOA', 'Angolan kwanza', 'Angola', 'Centimo', 100),
('ARS', 'Argentine peso', 'Argentina', 'Centavo', 100),
('AMD', 'Armenian dram', 'Armenia', 'Luma', 100),
('AWG', 'Aruban florin', 'Aruba', 'Cent', 100),
('AUD', 'Australian dollar', 'Australia', 'Cent', 100),
('AZN', 'Azerbaijani manat', 'Azerbaijan', 'Q?pik', 100),
('BSD', 'Bahamian dollar', 'Bahamas, The', 'Cent', 100),
('BHD', 'Bahraini dinar', 'Bahrain', 'Fils', 1000),
('BDT', 'Bangladeshi taka', 'Bangladesh', 'Poisha', 100),
('BBD', 'Barbadian dollar', 'Barbados', 'Cent', 100),
('BYN', 'Belarusian ruble', 'Belarus', 'Copeck', 100),
('BZD', 'Belize dollar', 'Belize', 'Cent', 100),
('BMD', 'Bermudian dollar', 'Bermuda', 'Cent', 100),
('BTN', 'Bhutanese ngultrum', 'Bhutan', 'Chetrum', 100),
('BOB', 'Bolivian boliviano', 'Bolivia', 'Centavo', 100),
('BAM', 'Bosnia and Herzegovina convertible mark', 'Bosnia and Herzegovina', 'Fening', 100),
('BWP', 'Botswana pula', 'Botswana', 'Thebe', 100),
('BRL', 'Brazilian real', 'Brazil', 'Centavo', 100),
('BND', 'Brunei dollar', 'Brunei', 'Sen', 100),
('BGN', 'Bulgarian lev', 'Bulgaria', 'Stotinka', 100),
('MMK', 'Burmese kyat', 'Myanmar', 'Pya', 100),
('BIF', 'Burundian franc', 'Burundi', 'Centime', 100),
('KHR', 'Cambodian riel', 'Cambodia', 'Sen', 100),
('CAD', 'Canadian dollar', 'Canada', 'Cent', 100),
('CVE', 'Cape Verdean escudo', 'Cape Verde', 'Centavo', 100),
('KYD', 'Cayman Islands dollar', 'Cayman Islands', 'Cent', 100),
('CLP', 'Chilean peso', 'Chile', 'Centavo', 100),
('COP', 'Colombian peso', 'Colombia', 'Centavo', 100),
('KMF', 'Comorian franc', 'Comoros', 'Centime', 100),
('CDF', 'Congolese franc', 'Congo, Democratic Republic of the', 'Centime', 100),
('CRC', 'Costa Rican col¢n', 'Costa Rica', 'C‚ntimo', 100),
('CUP', 'Cuban peso', 'Cuba', 'Centavo', 100),
('CZK', 'Czech koruna', 'Czech Republic', 'Heller', 100),
('DKK', 'Danish krone', 'Denmark', '', 100),
('DJF', 'Djiboutian franc', 'Djibouti', 'Centime', 100),
('DOP', 'Dominican peso', 'Dominican Republic', 'Centavo', 100),
('EGP', 'Egyptian pound', 'Egypt', 'Piastre[B]', 100),
('ERN', 'Eritrean nakfa', 'Eritrea', 'Cent', 100),
('ETB', 'Ethiopian birr', 'Ethiopia', 'Santim', 100),
('EUR', 'Euro', 'uro Zone', 'Cent', 100),
('FKP', 'Falkland Islands pound', 'Falkland Islands', 'Penny', 100),
('FJD', 'Fijian dollar', 'Fiji', 'Cent', 100),
('GMD', 'Gambian dalasi', 'Gambia, The', 'Butut', 100),
('GEL', 'Georgian lari', 'Georgia', 'Tetri', 100),
('GHS', 'Ghanaian cedi', 'Ghana', 'Pesewa', 100),
('GIP', 'Gibraltar pound', 'Gibraltar', 'Penny', 100),
('GTQ', 'Guatemalan quetzal', 'Guatemala', 'Centavo', 100),
('GNF', 'Guinean franc', 'Guinea', 'Centime', 100),
('GYD', 'Guyanese dollar', 'Guyana', 'Cent', 100),
('HTG', 'Haitian gourde', 'Haiti', 'Centime', 100),
('HNL', 'Honduran lempira', 'Honduras', 'Centavo', 100),
('HKD', 'Hong Kong dollar', 'Hong Kong', 'Cent', 100),
('HUF', 'Hungarian forint', 'Hungary', 'Fill‚r', 100),
('ISK', 'Icelandic kr¢na', 'Iceland', 'Eyrir', 100),
('INR', 'Indian rupee', 'India', 'Paisa', 100),
('IDR', 'Indonesian rupiah', 'Indonesia', 'Sen', 100),
('IRR', 'Iranian rial', 'Iran', 'Rial', 1),
('IQD', 'Iraqi dinar', 'Iraq', 'Fils', 1000),
('ILS', 'Israeli new shekel', 'Israel', 'Agora', 100),
('JMD', 'Jamaican dollar', 'Jamaica', 'Cent', 100),
('JPY', 'Japanese yen', 'Japan', 'Sen[C]', 100),
('JOD', 'Jordanian dinar', 'Jordan', 'Piastre[H]', 100),
('KZT', 'Kazakhstani tenge', 'Kazakhstan', 'TÕyn', 100),
('KES', 'Kenyan shilling', 'Kenya', 'Cent', 100),
('KWD', 'Kuwaiti dinar', 'Kuwait', 'Fils', 1000),
('KGS', 'Kyrgyz som', 'Kyrgyzstan', 'Tyiyn', 100),
('LAK', 'Lao kip', 'Laos', 'Att', 100),
('LBP', 'Lebanese pound', 'Lebanon', 'Piastre', 100),
('LSL', 'Lesotho loti', 'Lesotho', 'Sente', 100),
('LRD', 'Liberian dollar', 'Liberia', 'Cent', 100),
('LYD', 'Libyan dinar', 'Libya', 'Dirham', 1000),
('MOP', 'Macanese pataca', 'Macau', 'Avo', 100),
('MKD', 'Macedonian denar', 'North Macedonia', 'Deni', 100),
('MGA', 'Malagasy ariary', 'Madagascar', 'Iraimbilanja', 5),
('MWK', 'Malawian kwacha', 'Malawi', 'Tambala', 100),
('MYR', 'Malaysian ringgit', 'Malaysia', 'Sen', 100),
('MVR', 'Maldivian rufiyaa', 'Maldives', 'Laari', 100),
('MRU', 'Mauritanian ouguiya', 'Mauritania', 'Khoums', 5),
('MUR', 'Mauritian rupee', 'Mauritius', 'Cent', 100),
('MXN', 'Mexican peso', 'Mexico', 'Centavo', 100),
('MDL', 'Moldovan leu', 'Moldova', 'Ban', 100),
('MNT', 'Mongolian t”gr”g', 'Mongolia', 'M”ng”', 100),
('MAD', 'Moroccan dirham', 'Morocco', 'Centime', 100),
('MZN', 'Mozambican metical', 'Mozambique', 'Centavo', 100),
('NAD', 'Namibian dollar', 'Namibia', 'Cent', 100),
('NPR', 'Nepalese rupee', 'ÿÿNepal', 'Paisa', 100),
('TWD', 'New Taiwan dollar', 'Taiwan, Republic of China', 'Cent', 100),
('NZD', 'New Zealand dollar', 'New Zealand', 'Cent', 100),
('NIO', 'Nicaraguan c¢rdoba', 'Nicaragua', 'Centavo', 100),
('NGN', 'Nigerian naira', 'Nigeria', 'Kobo', 100),
('KPW', 'North Korean won', 'Korea, North', 'Chon', 100),
('NOK', 'Norwegian krone', 'Norway', '', 100),
('OMR', 'Omani rial', 'Oman', 'Baisa', 1000),
('PKR', 'Pakistani rupee', 'Pakistan', 'Paisa', 100),
('PAB', 'Panamanian balboa', 'Panama', 'Cent‚simo', 100),
('PGK', 'Papua New Guinean kina', 'Papua New Guinea', 'Toea', 100),
('PYG', 'Paraguayan guaran¡', 'Paraguay', 'C‚ntimo', 100),
('PEN', 'Peruvian sol', 'Peru', 'C‚ntimo', 100),
('PHP', 'Philippine peso', 'Philippines', 'Sentimo', 100),
('PLN', 'Polish z?oty', 'Poland', 'Grosz', 100),
('QAR', 'Qatari riyal', 'Qatar', 'Dirham', 100),
('CNY', 'Renminbi', "China, People's Republic of", 'Jiao[G]', 10),
('RON', 'Romanian leu', 'Romania', 'Ban', 100),
('RUB', 'Russian ruble', 'Russia', 'Kopeck', 100),
('RWF', 'Rwandan franc', 'Rwanda', 'Centime', 100),
('WST', 'Samoan t?l?', 'Samoa', 'Sene', 100),
('STN', 'SÆo Tom‚ and Pr¡ncipe dobra', 'SÆo Tom‚ and Pr¡ncipe', 'Cˆntimo', 100),
('SAR', 'Saudi riyal', 'Saudi Arabia', 'Halala', 100),
('RSD', 'Serbian dinar', 'Serbia', 'Para', 100),
('SCR', 'Seychellois rupee', 'Seychelles', 'Cent', 100),
('SLE', 'Sierra Leonean leone', 'Sierra Leone', 'Cent', 100),
('SGD', 'Singapore dollar', 'Singapore', 'Cent', 100),
('SBD', 'Solomon Islands dollar', 'Solomon Islands', 'Cent', 100),
('SOS', 'Somali shilling', 'Somalia', 'Cent', 100),
('ZAR', 'South African rand', 'South Africa', 'Cent', 100),
('KRW', 'South Korean won', 'Korea, South', 'Jeon', 100),
('SSP', 'South Sudanese pound', 'South Sudan', 'Piaster', 100),
('LKR', 'Sri Lankan rupee', 'Sri Lanka', 'Cent', 100),
('GBP', 'Sterling', 'United Kingdom', 'Penny', 100),
('SDG', 'Sudanese pound', 'Sudan', 'Piastre', 100),
('SRD', 'Surinamese dollar', 'Suriname', 'Cent', 100),
('SZL', 'Swazi lilangeni', 'Eswatini', 'Cent', 100),
('SEK', 'Swedish krona', 'Sweden', '™re', 100),
('CHF', 'Swiss franc', 'Switzerland', 'Rappen[J]', 100),
('SYP', 'Syrian pound', 'Syria', 'Piastre', 100),
('TJS', 'Tajikistani somoni', 'Tajikistan', 'Diram', 100),
('TZS', 'Tanzanian shilling', 'Tanzania', 'Cent', 100),
('THB', 'Thai baht', 'Thailand', 'Satang', 100),
('TOP', 'Tongan pa?anga[K]', 'Tonga', 'Seniti', 100),
('TTD', 'Trinidad and Tobago dollar', 'Trinidad and Tobago', 'Cent', 100),
('TND', 'Tunisian dinar', 'Tunisia', 'Millime', 1000),
('TRY', 'Turkish lira', 'Northern Cyprus', 'Kuru?', 100),
('TMT', 'Turkmenistani manat', 'Turkmenistan', 'Tenge', 100),
('UGX', 'Ugandan shilling', 'Uganda', '',NULL ),
('UAH', 'Ukrainian hryvnia', 'Ukraine', 'Kopeck', 100),
('AED', 'United Arab Emirates dirham', 'United Arab Emirates', 'Fils', 100),
('USD', 'United States dollar', 'United States', 'Cent[A]', 100),
('UYU', 'Uruguayan peso', 'Uruguay', 'Cent‚simo', 100),
('UZS', 'Uzbekistani sum', 'Uzbekistan', 'Tiyin', 100),
('VUV', 'Vanuatu vatu', 'Vanuatu', 'Cent', 100),
('VES', 'Venezuelan sovereign bol¡var', 'Venezuela', 'C‚ntimo', 100),
('YER', 'Yemeni rial', 'Yemen', 'Fils', 100),
('ZMW', 'Zambian kwacha', 'Zambia', 'Ngwee', 100);




