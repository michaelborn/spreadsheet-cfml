component extends="base" accessors="true"{

	property name="dateUtil" getter="false" setter="false";

	public any function getDateUtil(){
		if( IsNull( variables.dateUtil ) )
			variables.dateUtil = getClassHelper().loadClass( "org.apache.poi.ss.usermodel.DateUtil" );
		return variables.dateUtil;
	}

	// alternative BIF
	public boolean function _IsDate( required value ){
		if( !IsDate( arguments.value ) )
			return false;
		// Lucee will treat 01-23112 or 23112-01 as a date!
		if( ParseDateTime( arguments.value ).Year() > 9999 ) //ACF future limit
			return false;
		// ACF accepts "9a", "9p", "9 a" as dates
		// ACF no member function
		if( REFind( "^\d+\s*[apAP]{1,1}$", arguments.value ) )
			return false;
		return true;
	}

	public any function setFormats( struct dateFormats ){
		library().setDateFormats( defaultFormats() );
		if( !arguments.KeyExists( "dateFormats" ) )
			return this;
		var libraryInstanceFormats = library().getDateFormats();
		for( var format in arguments.dateFormats ){
			if( !libraryInstanceFormats.KeyExists( format ) )
				Throw( type=library().getExceptionType(), message="Invalid date format key", detail="'#format#' is not a valid dateformat key. Valid keys are DATE, DATETIME, TIME and TIMESTAMP" );
			libraryInstanceFormats[ format ] = arguments.dateFormats[ format ];
		}
		return this;
	}

	public string function getDefaultDateMaskFor( required date value ){
		if( isDateOnlyValue( arguments.value ) )
			return library().getDateFormats().DATE;
		if( isTimeOnlyValue( arguments.value ) )
			return library().getDateFormats().TIME;
		return library().getDateFormats().TIMESTAMP;
	}

	public boolean function isDateObject( required input ){
		return IsInstanceOf( arguments.input, "java.util.Date" );
	}

	public boolean function isDateOnlyValue( required date value ){
		var dateOnly = CreateDate( Year( arguments.value ), Month( arguments.value ), Day( arguments.value ) );
		return ( DateCompare( arguments.value, dateOnly, "s" ) == 0 );
	}

	public boolean function isTimeOnlyValue( required date value ){
		//NB: this will only detect CF time object (epoch = 1899-12-30), not those using unix epoch 1970-01-01
		return ( Year( arguments.value ) == "1899" );
	}

	public string function getPoiTimeZone(){
		return getClassHelper().loadClass( "org.apache.poi.util.LocaleUtil" ).getUserTimeZone();
	}

	public any function matchPoiTimeZoneToEngine(){
		if( library().getIsACF() )
			return this;//ACF doesn't allow the server/context timezone to be changed
		//Lucee allows the context timezone to be changed, which can cause problems with date calculations
		if( getPoiTimeZone() == GetTimezone() )
			return this;
		//Make POI match the Lucee timezone for the duration of the current thread
		getClassHelper().loadClass( "org.apache.poi.util.LocaleUtil" ).setUserTimeZone( GetTimezone() );
		return this;
	}

	/* Private */
	
	private struct function defaultFormats(){
		return {
			DATE: "yyyy-mm-dd"
			,DATETIME: "yyyy-mm-dd HH:nn:ss"
			,TIME: "hh:mm:ss"
			,TIMESTAMP: "yyyy-mm-dd hh:mm:ss"
		};
	}

}