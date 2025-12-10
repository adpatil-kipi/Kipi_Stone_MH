CALL SNOWFLAKE.DATA_PRIVACY.GENERATE_SYNTHETIC_DATA({
    'replace_output_tables': True,
    'datasets': [
        { 'input_table': 'MH_PERFORMANCE_TEST.SYNTHETIC_LAB.TEMP_SURVEY_AUGMENTED_1M', 'output_table': 'MH_PERFORMANCE_TEST.SYNTHETIC_LAB.FINAL_SURVEY_1M' ,'columns' : {'SURVEY_ID': {'join_key': True}}},
        { 'input_table': 'MH_PERFORMANCE_TEST.SYNTHETIC_LAB.TEMP_PATIENT_HISTORY_1M', 'output_table': 'MH_PERFORMANCE_TEST.SYNTHETIC_LAB.FINAL_HISTORY_1M' ,'columns' : {'HISTORY_ID': {'join_key': True}}},
        { 'input_table': 'MH_PERFORMANCE_TEST.SYNTHETIC_LAB.TEMP_WORKPLACE_1M', 'output_table': 'MH_PERFORMANCE_TEST.SYNTHETIC_LAB.FINAL_WORKPLACE_1M','columns' : {'COMPANY_ID': {'join_key': True}}},
        { 'input_table': 'MH_PERFORMANCE_TEST.SYNTHETIC_LAB.TEMP_DEMOGRAPHIC_EXTENDED_1M', 'output_table': 'MH_PERFORMANCE_TEST.SYNTHETIC_LAB.FINAL_DEMOGRAPHIC_EXTENDED_1M','columns' : {'SURVEY_ID': {'join_key': True}}},
        -- { 'input_table': 'MH_PERFORMANCE_TEST.SYNTHETIC_LAB.TEMP_MAPPINGS_1M',  'output_table': 'MH_PERFORMANCE_TEST.SYNTHETIC_LAB.FINAL_MAPPINGS_1M','columns' : {'COMPANY_ID': {'join_key': True}}},
{'input_table': 'MH_PERFORMANCE_TEST.SYNTHETIC_LAB.TEMP_TREATMENTS_OUTCOMES_1M', 'output_table': 'MH_PERFORMANCE_TEST.SYNTHETIC_LAB.FINAL_TREATMENTS_OUTCOMES_1M','columns' : {'OUTCOME_ID': {'join_key': True}}
}
        
    ]
});



CALL SNOWFLAKE.DATA_PRIVACY.GENERATE_SYNTHETIC_DATA({
    'replace_output_tables': True,
    'datasets': [
    {'input_table': 'MH_PERFORMANCE_TEST.SYNTHETIC_LAB.TEMP_MAPPINGS_1M',  'output_table': 'MH_PERFORMANCE_TEST.SYNTHETIC_LAB.FINAL_MAPPINGS_1M','columns' : {'COMPANY_ID': {'join_key': True}}
}
,
{ 'input_table': 'MH_PERFORMANCE_TEST.SYNTHETIC_LAB.TEMP_SURVEY_RESPONCE_DETAILS_1M', 'output_table': 'MH_PERFORMANCE_TEST.SYNTHETIC_LAB.FINAL_SURVEY_RESPONCE_DETAILS_1M','columns' : {'SURVEY_ID': {'join_key': True}}},
    
    ]
});
