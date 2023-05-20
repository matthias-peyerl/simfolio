# import contextlib
import yfinance as yf
from requests.exceptions import HTTPError
import yahoo_fin.stock_info as si
import pandas as pd


fr = pd.read_csv('filename.csv')
list_local_tickers = fr['symbol'].tolist()

ticker_list = si.tickers_other()
print(len(ticker_list))
count = 0
for ticker in ticker_list: #if ticker is already in the list, skip it
    # fr = pd.DataFrame()
    if '$' in ticker: #if ticker name contains $ or . , truncate $ or . and the rest
        ticker = ticker.split('$')[0]
    if '.' in ticker:
        ticker = ticker.split('.')[0]
        
    if ticker in list_local_tickers: #filter out tickers that are already in the csv
        continue
    try:
        company_info = yf.Ticker(ticker)
        new_row = pd.DataFrame([company_info.info])
        fr = pd.concat([fr, new_row], ignore_index=True)
        list_local_tickers.append(ticker)
        # Uncomment the following 3 lines to limit the number of tickers to be processed
        count+=1
        if count == 50: #tickers to be processed
            break
    except HTTPError as e:
        print(e, ticker)
        with open('error.txt', 'a') as f:
            f.write(ticker + '\n')
    # print(company_info.info.get('currentPrice'))

fr.to_csv('filename.csv', index=False, header=True)
