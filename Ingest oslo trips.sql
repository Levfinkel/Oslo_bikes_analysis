USE [master]
GO

/****** Object:  StoredProcedure [dbo].[Ingest_OsloTrips_FromJson]    Script Date: 11/22/2025 3:50:41 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER   PROCEDURE [dbo].[Ingest_OsloTrips_FromJson] @path nvarchar(4000)
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @json nvarchar(max);
  DECLARE @sql nvarchar(max) =
  N'SELECT @json = BulkColumn FROM OPENROWSET(BULK ''' + @path + N''', SINGLE_CLOB) AS src;';

  EXEC sys.sp_executesql @sql, N'@json nvarchar(max) OUTPUT', @json = @json OUTPUT;

  INSERT INTO dbo.oslo_bike_trips (
      started_at_utc, ended_at_utc, duration_sec,
      start_station_id, start_station_name, start_station_desc, start_lat, start_lon,
      end_station_id,   end_station_name,   end_station_desc,   end_lat,   end_lon
  )
  SELECT
      CAST([started_at] AS datetimeoffset(6)),
      CAST([ended_at]   AS datetimeoffset(6)),
      TRY_CONVERT(int,  [duration]),
      TRY_CONVERT(int,  [start_station_id]),
      [start_station_name],
      [start_station_description],
      TRY_CONVERT(decimal(10,7), [start_station_latitude]),
      TRY_CONVERT(decimal(10,7), [start_station_longitude]),
      TRY_CONVERT(int,  [end_station_id]),
      [end_station_name],
      [end_station_description],
      TRY_CONVERT(decimal(10,7), [end_station_latitude]),
      TRY_CONVERT(decimal(10,7), [end_station_longitude])
  FROM OPENJSON(@json) WITH (
      started_at                nvarchar(40)   '$.started_at',
      ended_at                  nvarchar(40)   '$.ended_at',
      duration                  int            '$.duration',
      start_station_id          nvarchar(10)   '$.start_station_id',
      start_station_name        nvarchar(200)  '$.start_station_name',
      start_station_description nvarchar(400)  '$.start_station_description',
      start_station_latitude    float          '$.start_station_latitude',
      start_station_longitude   float          '$.start_station_longitude',
      end_station_id            nvarchar(10)   '$.end_station_id',
      end_station_name          nvarchar(200)  '$.end_station_name',
      end_station_description   nvarchar(400)  '$.end_station_description',
      end_station_latitude      float          '$.end_station_latitude',
      end_station_longitude     float          '$.end_station_longitude'
  ) j;
END
GO
