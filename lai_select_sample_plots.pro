PRO LAI_select_sample_plots

  compile_opt IDL2
  envi,/restore_base_save_files
  envi_batch_init
  
  LAI_filepath='C:\Users\dell\Desktop\Revised\BJ\result\500m_NDVI\plot\20040401\'
  Ground_LatLong_indir='C:\Users\dell\Desktop\Revised\BJ\result\500GPS\'
  Geo_base_filepath='D:\Science\Validation\test_dss\L5_2\Geo_base\worldLandmask.tif'
;  Sample_plot_outdir='C:\Users\dell\Desktop\Revised\AH\NDVI_processed\NDVI_K_plot\20170423\'
  LAI_plot_outdir='C:\Users\dell\Desktop\Revised\BJ\result\U2_LAI\20040401\'
;  file_mkdir,LAI_plot_outdir
  ;
  
  LAI_dirpathlist=file_search(LAI_filepath,'*.tif',count = tif_count)
  Ground_LL_FilepathList=file_search(Ground_LatLong_indir,'*.csv',count=GLL_count)
  plot_Mean_LAI=dblarr(1,tif_count)
  plot_stdv_value=dblarr(1,tif_count)
  LAI_plot_central=dblarr(1,tif_count)
  ;Geo_base_file read
  envi_open_file,Geo_base_filepath,r_fid=base_fid
  envi_file_query,base_fid,ns=base_ns,nl=base_nl,dims=base_dims
  base_mapinfo=envi_get_map_info(fid=base_fid)
  for i_tif=0,tif_count-1 do begin
    ;
;    csv_name_strsplit=strsplit(file_basename(Ground_LL_FilepathList[i_csv]),'GPS',/extract)
;    csv_name=csv_name_strsplit[0]
    LAI_name=file_basename(LAI_dirpathlist[i_tif])
;    if csv_name ne LAI_name then print,'Ground&LAI Name not Match!'
;    if csv_name ne LAI_name then continue
    
    openr,txt_lun,Ground_LL_FilepathList[0],/get_lun
    LatLong_data_ground=dblarr(2,1000)
    txt_line=''
    point_count=long(0)
    while not eof(txt_lun) do begin
      readf,txt_lun,txt_line
      txt_value=strsplit(txt_line,',',/extract)
      if n_elements(txt_value) ne 2 then continue
      LatLong_data_ground[*,point_count]=txt_value
      point_count=point_count+1
    endwhile
    LatLong_data_ground=LatLong_data_ground[*,0:point_count-1]
    
    ;read LAI_tif
     envi_open_file,LAI_dirpathlist[i_tif],r_fid=tif_fid
     envi_file_query,tif_fid,ns=tif_ns,nl=tif_nl,dims=tif_dims
     LAI_tif_mapinfo=envi_get_map_info(fid=tif_fid)
     ndvi_data=envi_get_data(fid=tif_fid,pos=0,dims=tif_dims)
     
     envi_convert_projection_coordinates,LatLong_data_ground[1,i_tif],LatLong_data_ground[0,i_tif],base_mapinfo.proj,mapX,mapY,LAI_tif_mapinfo.proj
     envi_convert_file_coordinates,tif_fid,imgCol,imgRow,mapX,mapY
     Row_select=round(imgRow)
     Col_select=round(imgCol)
     NDVI_select_data=ndvi_data[Col_select,Row_select]
     LAI_plot_central[*,i_tif]=NDVI_select_data
     
     NDVI_data_cor= (ndvi_data lt -1)* 0+ (ndvi_data gt 1)*0 +(ndvi_data ge -1 and ndvi_data le 1)*ndvi_data

     LAI_data = alog(0.78/(0.93-NDVI_data_cor))*1.58
     LAI_data_cor = finite(LAI_data, /nan)*(-999) or (~finite(LAI_data, /nan))*LAI_data
     LAI_outname=LAI_plot_outdir+string('LAI_')+string(file_basename(LAI_filepath))+strmid(file_basename(LAI_dirpathlist[i_tif]),13,strlen(file_basename(LAI_dirpathlist[i_tif]))-17)+'.tif'
     envi_write_envi_file,LAI_data_cor,out_name=LAI_outname
     envi_setup_head,fname=LAI_outname,nb=1,ns=n_elements(LAI_data_cor[*,0]),nl=n_elements(LAI_data_cor[0,*]),$
       interleave=0,data_type=4,map_info=LAI_tif_mapinfo,/write

   
;     plot_Variance_value=dblarr(1,point_count)

     ;Search LAI value
;     envi_convert_projection_coordinates,LatLong_data_ground[1,i_tif],LatLong_data_ground[0,i_tif],base_mapinfo.proj,mapX,mapY,LAI_tif_mapinfo.proj
;     envi_convert_file_coordinates,tif_fid,imgCol,imgRow,mapX,mapY
;     for jIndex=0,n_elements(imgCol)-1 do begin
;       jX_UL=round(imgCol[jIndex]-2)
;       jX_LR=round(imgCol[jIndex]+3)
;       jY_UL=round(imgRow[jIndex]-2)
;       jY_LR=round(imgRow[jIndex]+3)
;       ndvi_select_data=ndvi_data[jX_UL:jX_LR,jY_UL:jY_LR]
      
       ValidIndex=where(LAI_data_cor gt 0 and LAI_data_cor ne -999, count)
       if ValidIndex[0] eq -1 then continue
       Mean_LAI_plot=mean(LAI_data_cor[ValidIndex])
;       variance_LAI_plot=variance(LAI_select_data[ValidIndex])
       stdv_LAI_plot=STDDEV(LAI_data_cor[ValidIndex])
       plot_Mean_LAI[*,i_tif]=Mean_LAI_plot
;       plot_Variance_value[*,jIndex]=variance_LAI_plot
       plot_stdv_value[*,i_tif]=stdv_LAI_plot
       
;       envi_convert_file_coordinates,tif_fid,jX_UL,jY_UL,gps_mapX,gps_mapY,/To_Map
;       ;envi_convert_projection_coordinates,gps_mapX,gps_mapY,base_mapinfo.proj,gps_Lon,gps_Lat,LAI_tif_mapinfo.proj
;       gps_mapinfo=LAI_tif_mapinfo
;       gps_mapinfo.MC[2:3]=[gps_mapX,gps_mapY]
;       NDVI_select_outname=Sample_plot_outdir+strmid(file_basename(LAI_name[0]),0,strlen(file_basename(LAI_name[0]))-6)+'_Point'+strtrim(string(jIndex+1),2)+'.tif'
;       envi_write_envi_file,ndvi_select_data,out_name=NDVI_select_outname
;       envi_setup_head,fname=NDVI_select_outname,nb=1,ns=n_elements(ndvi_select_data[*,0]),nl=n_elements(ndvi_select_data[0,*]),$
;         interleave=0,data_type=4,map_info=gps_mapinfo,/write

     endfor    
;  endfor
print,'Finished!'  
end