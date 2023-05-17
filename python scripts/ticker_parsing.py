
import yfinance as yf
from requests.exceptions import HTTPError
import yahoo_fin.stock_info as si
import pandas as pd

ticker_list = si.tickers_other()
print(len(ticker_list))
fr = pd.DataFrame()
for ticker in ticker_list[:6000]:
    try:
        company_info = yf.Ticker(ticker)
        new_row = pd.DataFrame([company_info.info])
        fr = pd.concat([fr, new_row], ignore_index=True)
    except HTTPError as e:
        print(e, ticker)
        with open('error.txt', 'a') as f:
            f.write(ticker + '\n')
    # print(company_info.info.get('currentPrice'))
    fr.to_csv('filename.csv', index=False)

