bin\bash

module load R/3.5.0

R --vanilla <<"EOF"
library(rjson, lib.loc="/re_gecip/shared_allGeCIPs/matthias/Rlibrary") #Rlabkey_2.1.13
library(Rlabkey, lib.loc="/re_gecip/shared_allGeCIPs/matthias/Rlibrary") #Rlabkey_2.1.13
labkey.setDefaults(baseUrl="http://emb-prod-mre-labkey-01.gel.zone:8080/labkey/")

#--------------------------------------------------- retrieve pheno participant
participant=labkey.executeSql(folderPath="/main-programme/main-programme_v4_2018-07-31",
	schemaName="lists", 
	sql =	'SELECT DISTINCT ra.Participant_Id,ra.Rare_Diseases_Family_Id, rd.Hpo_Id, ra.Participant_Type,fam1.Family_Group_Type, ra.Participant_Phenotypic_Sex,p.Year_Of_Birth,p.Participant_Ethnic_Category,ra.Genome_Build,ra.Path,ft.Filename, pd.Normalised_Specific_Disease,pd.Specific_Disease,pd.Disease_Sub_Group, pd.Disease_Group,pd.Diagnosis_Date
		FROM rare_disease_analysis AS ra
		LEFT JOIN rare_diseases_participant_phenotype AS rd ON ra.Participant_Id=rd.Participant_Id
		LEFT JOIN rare_diseases_participant_disease AS pd ON ra.Participant_Id = pd.Participant_Id 
		LEFT JOIN sequencing_report AS sq ON ra.Participant_Id = sq.Participant_Id 
		LEFT JOIN genome_file_paths_and_types AS ft ON ra.Participant_Id = ft.Participant_Id
		LEFT JOIN participant AS p ON ra.Participant_Id = p.Participant_Id
		LEFT JOIN rare_diseases_family as fam1 ON p.Rare_Diseases_Family_Id = fam1.Rare_Diseases_Family_Id
		WHERE rd.Hpo_Id = \'HP:0002205\' AND rd.Hpo_Present = \'Yes\' AND ra.Participant_Type = \'Proband\' AND ft.File_Sub_Type =\'Genomic VCF\' ',
        maxRows = 1e+06 )
head(participant)
table(duplicated(participant[,1]))
participant=participant[!duplicated(participant[,1]),]
table(duplicated(participant[,1]))
write.csv(participant, file="participant_HPO_0002205.csv",row.names=F)

#--------------------------------------------------- get trios
trio.dat=labkey.executeSql(folderPath="/main-programme/main-programme_v4_2018-07-31",
	schemaName="lists", 
	sql=	'SELECT p.Participant_Id,p.Rare_Diseases_Family_Id,fam1.Family_Group_Type,p.Biological_Relationship_To_Proband,p.Programme_Consent_Status, p.Participant_Phenotypic_Sex,sq.Status,ft.File_Path,ft.Genome_Build,ft.Filename
		FROM participant AS p 
		LEFT JOIN genome_file_paths_and_types AS ft ON p.Participant_Id = ft.Participant_Id
		LEFT JOIN sequencing_report AS sq ON p.Participant_Id = sq.Participant_Id	
		LEFT JOIN rare_diseases_family as fam1 ON p.Rare_Diseases_Family_Id = fam1.Rare_Diseases_Family_Id
		WHERE ft.File_Sub_Type =\'Genomic VCF\' 
		',
        maxRows = 1e+06 )

trio.dat=trio.dat[!duplicated(trio.dat[,1]),]
trio.dat=trio.dat[trio.dat[,2] %in% participant[,2],]  #subset dataframe to family IDs present in patricipant table 
trio.dat[,8] = paste(trio.dat[,8] ,"Variations/",sep="/")  #update file path to location of gVCF files
trio.dat=trio.dat[!duplicated(trio.dat[,1]),]
trio.dat$Participant_Type=rep("Relative",nrow(trio.dat))
trio.dat$Participant_Type[trio.dat[,1] %in% participant[,1]] =c("Proband")
table(duplicated(trio.dat[,1]))
head(trio.dat)
write.csv(trio.dat, file="trio_dat_HPO_0002205.csv",row.names=F)

EOF
