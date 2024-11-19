import os
import pandas as pd
from sqlalchemy import create_engine

# connect parameters
server = 'commonspirit-we-2024-10-30-13-33.chb4jcogywlz.us-east-1.rds.amazonaws.com'
database = 'Analytics'
username = 'admin'
password = 'TJ7RPb4foa4GwfygAb3A'

# connect to database
engine = create_engine(f"mssql+pyodbc://{username}:{password}@{server}/{database}?driver=ODBC+Driver+17+for+SQL+Server")

output_path = os.path.dirname(os.path.abspath(__file__)) +f"\\changelog\\catalogs\\"

def export_table_to_csv(table_name, engine, output_path):
    
    output_file = f"{output_path}\\{table_name}.csv"

    #  get data
    query = f"SELECT * FROM dbo.{table_name}"
    
    # load data to DataFrame
    df = pd.read_sql(query, engine)
    
    # save data
    df.to_csv(output_file, index=False, quotechar='"', quoting=1)

export_table_to_csv('AddendumB', engine, output_path)
export_table_to_csv('cw_OfferRatesByState', engine, output_path)
export_table_to_csv('cw_OfferRatesLowVolume', engine, output_path)
export_table_to_csv('f835_AdjustmentCodes', engine, output_path)
export_table_to_csv('f835_RemarkCodes', engine, output_path)
export_table_to_csv('MedicareRates', engine, output_path)
export_table_to_csv('PlaceOfService', engine, output_path)
export_table_to_csv('APRDRG', engine, output_path)
export_table_to_csv('MSDRG', engine, output_path)
export_table_to_csv('HCPCS_Alphanumeric', engine, output_path)
export_table_to_csv('cw_RevCodes', engine, output_path)
export_table_to_csv('cw_EmergencyRevCodes', engine, output_path)
export_table_to_csv('cw_EmergencyCPTs', engine, output_path)
