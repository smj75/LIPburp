# GIVEN A LIST OF RANDOM NUMBERS (5 COLUMNS)
# MAKE A LIST OF SILL DIMENSIONS / HOSTROCK CHARACTER

BEGIN{ 

	pi = 3.141592654;
	SQRT2 = sqrt(2);

} 

{

# SURFACE AREA, ALREADY DETERMINED FROM FIRST RANDOM NUMBER

	getline A <"tmp.sample1d.out"; 
	if ( NORMAL == 0 ) A = exp(A); 
	if ( A < 0 ) A = 0; 	

# THICKNESS AT CENTRE, FROM 2ND RANDOM NUMBER

	if (A==0) {
		S = 120;
	} else {
		dS = 0 + 100 * SQRT2 * erfinv(2 * $2 - 1);
#		dS = ($2-0.5)*200;
#		S = 120 + 0.02568 * sqrt(A*1e6/pi) + ($2-0.5)*200;
		S = 120 + 0.02568 * sqrt(A*1e6/pi) + dS;
	}
	if (S > 600) S = 600; 
	if (S < 0) S = 1; 

# WEIGHT FRACTION OF HOST ROCK THAT CONVERTS TO METHANE, 
# FROM 3RD RANDOM NUMBER

#	W = 0.005 + $3*0.015;  # SVENSEN ET AL. (2004) RANGE 
#	W = 0.0125 + 0.0075 * SQRT2 * erfinv(2 * $3 - 1);
	W = 0.014 + 0.0044 * SQRT2 * erfinv(2 * $3 - 1);
	if ( W < 0 ) W = 0;

# DEPTH OF INTRUSION, FROM 4TH RANDOM NUMBER

#	Z = 0.5+$4*3; 
	if ( $4 < 0.22221) {
		Z = 0.2 + 0.3 * $4;
	} else {
		Z = 1.15 + 0.85 * SQRT2 * erfinv(2 * $4 - 1);
	}

# RATIO OF LABILE:REFRACTORY KEROGEN, FROM 5TH RANDOM NUMBER

	K = $5; 
	
# POWER CONTROLLING PROFILE SHAPE, FROM 6TH RANDOM NUMBER

	P = exp( -0.221218 + 0.342635 * SQRT2 * erfinv(2 * $6 - 1) );

# TIME SHIFT RELATIVE TO CONSTANT RECURRENCE TIME PERIOD, FROM 7TH NUMBER
# SHIFT IN RADIUS RELATIVE TO PLUME HEAD MODEL, FROM 8TH RANDOM NUMBER
# AZIMUTH, FROM 9TH RANDOM NUMBER
# ARE CALCULATED IN MAKE_LOCATIONS.AWK
# RANDOM NUMBERS ARE PASSED ON HERE
	
	print A, S, W, Z, K, P, $7, $8, $9; 

}

function erfinv(xx) {
	lomxsq=log(1-xx*xx); 
	ca=0.140012; 
	topi=0.636619772;
	topia=topi/ca;
	b=topia+0.5*lomxsq;
	b2=b*b;
	sr1=sqrt(b2-lomxsq/ca);
	sr2=sqrt(sr1-b);
	if ( xx >= 0) {return sr2} else {return -sr2};
}


function erf(xx) {
	xsq=xx*xx; 
	fopi=1.273239545; 
	ca=0.140012; 
	caxsq=ca*xsq; 
	ce=exp(-xsq*(fopi+caxsq)/(1+caxsq)); 
	cs=sqrt(1-ce); 
	if ( xx >= 0) {return cs} else {return -cs}
} 

