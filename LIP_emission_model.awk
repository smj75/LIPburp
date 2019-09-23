BEGIN{

# THIS VERSION MODIFIED FROM VERSION USED TO PRODUCE NATURE DRAFT
# TO LOOP OVER A CONSTANT TIME PERIOD RATHER THAN OVER SILLS ONE BY ONE
# 
# AND FURTHER REVISED SO AS NOT TO DOUBLE COUNT EMISSIONS 
# FROM SILLS INTRUDED IN THE SAME PLACE

	calculate_province = 1;
	aspect_ratio = 0.417;
	plume_head_azimuth = 45;
#	thermal_maturation_pow = 0.56; 
	if ( mantle_area_flux == 0 ) mantle_area_flux = 6.7;	
	pulse_width = 40000;
	asthenosphere_channel_half_thickness = 50e3;
	mantle_thermal_diffusivity = 1.0e-6 * 60 * 60 * 24 * 365;
	delC_mantle = -7;
	area_density = 0.073;
	pulse_model = 2; # 1 FOR NO VERTICAL DIFFUSION, 2 FOR TAYLOR DISPERSION
	time_variation_scale = 0;
	qmult_CO2_lava = 0.0141;	# BACKGROUND CO2 FLUX FROM LAVA
	qmult_CO2_lava = 0.0;	# BACKGROUND CO2 FLUX FROM LAVA
	background_C_emissions = 0.071; # GLOBAL BACKGROUND EMISSIONS LEVEL
	background_C_emissions = 0.0; # GLOBAL BACKGROUND EMISSIONS LEVEL
	
	plume_head_marker = 0;	# 0 FOR MAX TEMPERATURE, 1 for CONSTANT VALUE, 2 FOR VARIABLE 
# USED FOR  plume_head_marker=1 OPTION 
#	if ( plume_head_edge_constant == 0 ) plume_head_edge_constant = 0;	
	plume_head_edge_constant = 2.5;
	
	pi = 3.141592654; 
	sqrttwo = sqrt(2);
	deg2rad = 2.0 * pi / 360;
	srand();

# TIME SCALE FOR TAYLOR DISPERSION MODEL

	effective_diffusivity = 2 * mantle_area_flux^2 * asthenosphere_channel_half_thickness^2 / 105 / mantle_thermal_diffusivity;
	taylor_dispersion_radius_scale = sqrt( effective_diffusivity / 2 / pi / mantle_area_flux );
#	taylor_dispersion_radius_scale = sqrt( mantle_area_flux * asthenosphere_channel_half_thickness^2 / 105 / pi / mantle_thermal_diffusivity );


#
# MODEL FOR CHANGE IN INTRUDED AREA OVER TIME
#

# PALAEOGEOGRAPHY INFORMATION
# dAdR_max IS THE CHANGE IN SILL PROVINCE AREA (= DEEP BASIN CHAIN)
# WITH RESPECT TO LONG RADIUS OF PLUME HEAD

	dAdR_max = dadr_ellipse_chain_72();
#	dAdR_max = dadr_ellipse_chain_73();

	N_dfdt_seg = 0;
	freq[0] = 0;
		print "i, time, freq, repeat_time, area_density, dAdt" >"LIP_emission_model.area.model";

	for ( i=1; i<=nmax; i++ ) {

# RELATIONSHIP BETWEEN AREA AND LONG RADIUS FOR AN ELLIPTICAL PLUME HEAD

		A = pi * r[i]^2 * aspect_ratio;

# TIME ASSOCIATED WITH A GIVEN AREA
# DEPENDS ON THE MARKER USED FOR THE EDGE OF THE INTRUDED AREA
 
		if ( plume_head_marker == 0 ) {
			time_tau[i] = A / (1.5 * mantle_area_flux);
		} else if ( plume_head_marker == 1 ) {
			time_tau[i] = (A - plume_head_edge_constant * mantle_area_flux * pulse_width) / (1.5 * mantle_area_flux);
#		} else if ( plume_head_marker == 2 ) {
#			time_tau[i] = A / (plume_head_edge_variable[i] + 1.5 * mantle_area_flux);
		}

# SILL AREA DENSITY INFORMATION

		if ( area_density_constant != 0 ) {
			area_density = area_density_constant;
		} else {
#			area_density = 0.07 * 250 / r[i];
			area_density = 0.07 * exp(-(r[i]/600)^2);
			if ( area_density > 0.1 ) area_density = 0.1;
		}
		
		
		if ( dadr[i] <= 0.0 ) {
			freq[i] = 0;
			tau[i] = 4.567e9;
		} else {
		
# SPEED OF LONG RADIUS PLUME EDGE MARKER

		if ( plume_head_marker == 0 ) {
			dRdt = 0.5 * sqrt( 1.5 * mantle_area_flux / (aspect_ratio * pi * time_tau[i]));
		} else if ( plume_head_marker == 1 ) {
#			dRdt = 0.75 * sqrt( mantle_area_flux * pulse_width / (aspect_ratio * pi * ( plume_head_edge_constant + 1.5 * time_tau[i] / pulse_width)));
			dRdt = 1.5 * sqrt( mantle_area_flux / (aspect_ratio * pi * ( 4.0 * plume_head_edge_constant * pulse_width + 6.0 * time_tau[i] )));
#			dRdt = 0.5 * sqrt( 1.5 * mantle_area_flux / (aspect_ratio * pi * time_tau[i]));
		}
			
# SILL REPEAT FREQUENCY AND PERIOD

			freq[i] = area_density * dadr[i] * dRdt;
			tau[i] = 1.0 / freq[i];
		}
#		print i, time_tau[i], freq[i], tau[i], area_density, dadr[i]*dRdt >"LIP_emission_model.area.model";
	}

#
#
#

# READ IN INFORMATION FOR RANGE OF AZIMUTHS
# AZIMUTH FILE IS ASSUMED TO HAVE EXACTLY THE 
# SAME NUMBER OF ROWS AS THE INTRUDED AREA FILE

	if ( azimuth_file ) {
		for ( i=1; i<=nmax; i++ ) {
			getline < azimuth_file;
			if ( i==1 && !$1 ) {
				print " Azimuth file "azimuth_file" does not exist";
				calculate_province = 0;
				exit;
			}
			if ( $1 == r[i]) {
				az_start_1[i] = $2;
				az_end_1[i] = $3;
				az_start_2[i] = $4;
				az_end_2[i] = $5;
			} else {
				print " Azimuth file "azimuth_file" does not have correct radii";
				calculate_province = 0;
				exit;
			}
#			print r[i], az_start_1[i], az_end_1[i], az_start_2[i], az_end_2[i];
		}
	}

# READ IN CUMULATIVE FREQUENCY TABLE
# FOR STOCHASITIC VARIATION IN RADIUS 
# FILE CONTAINS
# SCALED TIME, SCALED SHIFTED AREA, PDEN, PCUM
# TIME IS SCALED BY THE PULSE WIDTH
# AREA IS SCALED BY AREA FLUX * PULSE WIDTH
# AREA IS SHIFTED BY 1.5 * SCALED TIME, WHICH PUTS ZERO AREA AT MAX PDEN

	if ( radial_variation_file ) {
		t_test = -999;
		nrv_t = 0;
		for ( i=1; i<=10000; i++ ) {
			if ( getline < radial_variation_file ) {
				nrv++;
				if ( $1 != t_test ) {
					nrv_t++;
					t_test = $1;
					nrv_r = 1;
				} else {
					nrv_r++;
				}
				if ( nrv_r == 1 ) srad_time[nrv_t] = $1 * pulse_width;
				srad_rad[nrv_t][nrv_r] = $2;
				srad_p[nrv_t][nrv_r] = $3;
				srad_pcum[nrv_t][nrv_r] = $4;
			} else {
				break;
			}
		}
#		print "Records in radius file: ", nrv, nrv_t, nrv_r;
	}
#for (j=1; j<=nrv_t; j++) for (i=1; i<=nrv_r; i++) print srad_time[j], mantle_area_flux * srad_time[j], srad_rad[j][i],  srad_p[j][i], srad_pcum[j][i];
#exit;

#
# READ IN PRE-DETERMINED RECURRENCE TIME HISTORY
#

	if ( t_rec_file ) {
		ntrec = 0;
		while ( (getline < t_rec_file) ) {
			ntrec++;
			trec_age[ntrec] = $1;
			trec_tau[ntrec] = $2;
#			print ntrec, trec_age[ntrec], trec_tau[ntrec];
		};
		close (t_rec_file);
		if ( ntrec==0 ) {
			print " Recurrence time file "t_rec_file" does not exist";
			calculate_province = 0;
		} 
	}

##

	i = 0;
	i_srad_t = 1;
  	do {i++} while ( freq[i] == 0.0 );
	time = time_tau[i-1];
	t_0 = time;
	t_abs[1] = t_0;
	t_rel0[1] = 0;
	prov_area[0] = 0;
	prov_aur_vol[0] = 0;
	prov_sill_vol[0] = 0;
	prov_aur_overlap_vol = 0.0;
	prov_overlap_area = 0.0;

}

#
# READ IN SILL PROVINCE DATA
#

{

	if ( t_rec_file && time > trec_age[ntrec] ) exit;

# PARAMETERS FOR THIS SILL
# 1. SILL SEQUENCE NUMBER
# 2. SUB-SILL SEQUENCE NUMBER (TO DEAL WITH VARIATION OF THICKNESS)
# 3. TOTAL NUMBER OF SUB-SILLS THIS SILL IS DIVIDED INTO
# 4. TOTAL MASS PER UNIT SURFACE AREA
# 5. MATURATION DECAY TIME
# 6. MATURATION POWER LAW EXPONENT
# 7. TOTAL MASS OF CO2 DEGASSED FROM MAGMA
# 8. TIME TO SOLIDIFICATION OF MAGMA
# 9. PROPORTION LABILE:REFRACTORY KEROGEN
# 10. RANDOM NUMBER TO DETERMINE VARIATION IN INTRUSION TIME
# 11. RANDOM NUMBER TO DETERMINE VARIATION IN LOCATION RADIUS
# 12. RANDOM NUMBER TO DETERMINE VARIATION IN LOCATION AZIMUTH
# 13. N CONSECUTIVE BIG SILLS (NOT USED HERE)
# 14. SILL SURFACE AREA (km2)
# 15. SILL MAXIMUM THICKNESS (m, converted to km)
# 16. SILL SCALED AUREOLE THICKNESS (dless)
# 17. SILL EMPLACEMENT DEPTH (km)

	m[$1][$2] = $4; 
	t_decay[$1][$2] = $5; 
	p[$1][$2] = $6;
	m_CO2[$1][$2] = $7;
	t_solid[$1][$2] = $8;
	sill_thickness[$1][$2] = $15/1000;
	aureole_thickness_scaled[$1][$2] = $16;
	if ($2 == 0) {
		N_annuli[$1] = $3;
		CH4_source[$1] = $9;
		ran_dtime = $10;
		ran_drad = $11;
		ran_daz = $12;
		t_vent[$1] = 0.001;
		sill_area[$1] = $14;
		sill_depth[$1] = $17;
	}
	
# DERIVED SILL & PROVINCE DIMENSIONS

	sill_radius[$1] = sqrt( sill_area[$1] / pi );
	sill_vol[$1] = sill_area[$1] * sill_thickness[$1][0];
	aur_vol[$1] = sill_vol[$1] * aureole_thickness_scaled[$1][0];
	prov_area[$1] = prov_area[$1-1] + sill_area[$1];
	prov_aur_vol[$1] = prov_area[$1-1] + aur_vol[$1];
	prov_sill_vol[$1] = prov_area[$1-1] + sill_vol[$1];

#	if ($2 == 1) aureole_thickness_scaled[$1] = $16;
#	aureole_thickness_scaled[$1] = 0.0;

# TIME THAT THIS SILL WILL BE INTRUDED

	if ( $2 == 0 ) {
		if ( t_rec_file ) {
			if ( $1 == 1 ) {
				t_rec[$1] = trec_tau[1];
#print time, t_abs[$1], t_rel0[$1];
			} else {
				j = 1;
				do {j++} while (trec_age[j] <= time);
				t_rec[$1] = trec_tau[j-1] + (trec_tau[j]-trec_tau[j-1]) * (time-trec_age[j-1]) / (trec_age[j]-trec_age[j-1]);
#				t_rec[$1] = 4.0;
#print j, trec_age[j], time, t_rec[$1];
			}
			
		} else if ( ! t_rec_const || t_rec_const <= 0.0 ) {

			for (j=i; j<=nmax+1; j++) {
				if ( i > nmax ) exit;
				s1 = freq[i-1]^2 * (time - time_tau[i])^2;
				s2 = 2*freq[i-1] * (freq[i] * (time - time_tau[i-1]) * (time - time_tau[i]) + 2*(time_tau[i] - time_tau[i-1]) );
				s3 = freq[i] * (freq[i] * (time - time_tau[i-1])^2 + 4*(time_tau[i] - time_tau[i-1]) );
				sterm = s1 - s2 + s3;
				if ( sterm <= 0 )	exit;
  				dt = ( -sqrt( sterm ) + freq[i-1] * (time_tau[i] - time) + freq[i] * (time - time_tau[i-1]) ) / (2 * ( freq[i-1] - freq[i] ));
  
  				if ( (time+dt) > time_tau[i] ) {
  					time = time_tau[i];
  					i++;
  					if (i > nmax) exit;
  					continue;
  				}	  
			  	t_rec[$1] = dt;
			}

		} else {
			t_rec[$1] = t_rec_const;
		}

# VARIATION IN TIME
## YET IMPLEMENTED BELOW

		d_time = time_variation_scale * sqrttwo * erfinv( 2 * ran_dtime - 1 );

# TIME

		time += t_rec[$1];
		t_abs[$1] = time;
		t_rel0[$1] = t_abs[$1] - t_0;
	
# RADIUS

		if ( plume_head_marker == 0 ) {
			area_inside_marker = 1.5 * mantle_area_flux * time;
		} else if ( plume_head_marker == 1 ) {
			area_inside_marker = plume_head_edge_constant * mantle_area_flux * pulse_width + 1.5 * mantle_area_flux * time;
		}
		radius_max[$1] = sqrt( area_inside_marker / aspect_ratio / pi );

#
# VARIATION IN RADIUS
#

#		ran_drad = 0.95;

# BILINEAR INTERPOLATION

		if ( radial_variation_file ) {

			while ( time >= srad_time[i_srad_t] ) i_srad_t++;
			i_srad_r = 0;
			do { i_srad_r++ } while ( srad_pcum[i_srad_t-1][i_srad_r] <= ran_drad );
			a1 = srad_rad[i_srad_t-1][i_srad_r-1] + (srad_rad[i_srad_t-1][i_srad_r] - srad_rad[i_srad_t-1][i_srad_r-1]) * (ran_drad - srad_pcum[i_srad_t-1][i_srad_r-1]) / (srad_pcum[i_srad_t-1][i_srad_r] - srad_pcum[i_srad_t-1][i_srad_r-1]);
			i_srad_r = 0;
			do { i_srad_r++ } while ( srad_pcum[i_srad_t][i_srad_r] <= ran_drad );
			a2 = srad_rad[i_srad_t][i_srad_r-1] + (srad_rad[i_srad_t][i_srad_r] - srad_rad[i_srad_t][i_srad_r-1]) * (ran_drad - srad_pcum[i_srad_t][i_srad_r-1]) / (srad_pcum[i_srad_t][i_srad_r] - srad_pcum[i_srad_t][i_srad_r-1]);

# RE-INTRODUCE DIMENSIONS
# TIME IS SCALED BY THE PULSE WIDTH
# AREA IS SCALED BY AREA FLUX * PULSE WIDTH
# AREA IS SHIFTED BY 1.5 * SCALED TIME, WHICH PUTS ZERO AREA AT MAX PDEN
	
			a0 = 1.5 * time / pulse_width;
			if ( a0 == 0 ) {
				a1 *= area_inside_marker / a0;
				a2 *= area_inside_marker / a0;
				relative_sill_location_area = 0.0;
				relative_sill_location_radius = 0.0;
			} else {	
				a1 *= area_inside_marker / a0;
				a2 *= area_inside_marker / a0;
				relative_sill_location_area = a1 + (a2 - a1) * (time - srad_time[i_srad_t-1]) /	 (srad_time[i_srad_t] - srad_time[i_srad_t-1]);
				if ( relative_sill_location_area < 0.0 ) {
					relative_sill_location_radius = -sqrt( -relative_sill_location_area / aspect_ratio / pi );
				} else {
					relative_sill_location_radius = sqrt( relative_sill_location_area / aspect_ratio / pi );
				}
			}

#		sill_location_radius_max = a1 + (a2 - a1) * (time - srad_time[i_srad_t-1]) / (srad_time[i_srad_t] - srad_time[i_srad_t-1]);
#		relative_sill_location_area = a1 + (a2 - a1) * (time - srad_time[i_srad_t-1]) / (srad_time[i_srad_t] - srad_time[i_srad_t-1]);

			sill_location_area = area_inside_marker + relative_sill_location_area;
			if ( sill_location_area < 0.0 ) {
				next;
				sill_location_radius_max = 999.0;
			} else {
				sill_location_radius_max = sqrt( sill_location_area / aspect_ratio / pi );
			}
			d_radius = radius_max[$1] - sill_location_radius_max;

			i_srad_r = 0;
			do { i_srad_r++ } while ( srad_pcum[i_srad_t-1][i_srad_r] < 1.0 );
			r1test = srad_rad[i_srad_t-1][i_srad_r];
			i_srad_r = 0;
			do { i_srad_r++ } while ( srad_pcum[i_srad_t][i_srad_r] < 1.0 );
			r2test = srad_rad[i_srad_t][i_srad_r-1];

#		if ( pulse_model == 2 ) {

# RUDGE ET AL. 2008 EQ C.8 

#				d_radius = taylor_dispersion_radius_scale * sqrttwo * erfinv( 2 * ran_drad - 1 n);
#			}
		} else {
			sill_location_radius_max = ran_drad * radius_max[$1];
		}

#print "here";
#exit;


#
# AZIMUTH
#

		if ( azimuth_file ) {
			naz = 0;
#			do {naz++} while (r[naz] <= radius_max[$1]);
			do {naz++} while (r[naz] <= sill_location_radius_max);
			if ( naz > nmax ) exit;

#			az_interp = (radius_max[$1] - r[naz-1]) / (r[naz] - r[naz-1]);
			az_interp = (sill_location_radius_max - r[naz-1]) / (r[naz] - r[naz-1]);

			az_start = az_interp * (az_start_1[naz] - az_start_1[naz-1]) + az_start_1[naz-1];
		
			az_range_0 = (az_end_1[naz-1] - az_start_1[naz-1]) + (az_end_2[naz-1] - az_start_2[naz-1]);
			az_range_1 = (az_end_1[naz] - az_start_1[naz]) + (az_end_2[naz] - az_start_2[naz]);
			az_range = az_interp * (az_range_1 - az_range_0) + az_range_0;

			az_cut_0 = az_end_1[naz-1];
			az_cut_1 = az_end_1[naz];
			az_cut = az_interp * (az_cut_1 - az_cut_0) + az_cut_0;

			az_jump_0 = az_start_2[naz-1] - az_end_1[naz-1];
			az_jump_1 = az_start_2[naz] - az_end_1[naz];
			az_jump = az_interp * (az_jump_1 - az_jump_0) + az_jump_0;

			sill_location_azimuth[$1] = az_start + ran_daz * az_range;
			if ( sill_location_azimuth[$1] > az_cut ) sill_location_azimuth[$1] += az_jump;

		} else {
			sill_location_azimuth[$1] = ran_daz * 360;
		}
	
#		sill_location_azimuth = -plume_head_azimuth;
	
# CORRECT SILL LOCATION RADIUS FOR PLUME HEAD ELLIPTICITY

		sill_location_radius[$1] = sill_location_radius_max * aspect_ratio / sqrt( (aspect_ratio * cos( (sill_location_azimuth[$1] + plume_head_azimuth)*deg2rad ))^2 + sin(  (sill_location_azimuth[$1] + plume_head_azimuth)*deg2rad )^2 );


# END OF IF ($2 == 0) I.E. AVERAGE SILL LOOP 

	}

	N_sills = $1;


#
# DETERMINE WHETHER THIS SILL INTRUDES AN EXISTING AUREOLE
#
	if ( $2==$3 && radial_variation_file ) {

		n_overlap = 0;
		r1 = sill_location_radius[$1]; 
		az1 = sill_location_azimuth[$1] * deg2rad;
		sill_overlap_area = 0.0;
		sill_overlap_vol = 0.0;

# LOOP OVER EXISTING SILLS
# DISTANCE BETWEEN CENTRES OF NEW SILL AND EXISTING SILLS, D

		for (j=1; j<$1; j++){ 
			r2 = sill_location_radius[j]; 
			az2 = sill_location_azimuth[j] * deg2rad;
			d = sqrt( r1*r1 + r2*r2 - 2.0*r1*r2 * cos(az1-az2) );
					
# DO THESE SILLS OVERLAP IN PLAN VIEW?

			ra = sill_radius[$1] = sqrt( sill_area[$1] / pi );
			rb = sill_radius[j];
			if ( d < (ra+rb) ) {
				n_overlap ++;
				dd[n_overlap] = d;
				jj[n_overlap] = j;
			}
		}
		
# EACH SILL IS DIVIDED INTO SUB-SILLS OF EQUAL SURFACE AREA
# LOOP OVER EACH SUB-RADIUS OF NEWLY INTRUDED SILL
#  LOOP OVER EACH EXISTING SILLS WITH AT LEAST PARTIAL OVERLAP
#   LOOP OVER EACH SUB-RADIUS OF EXISTING SILL

		aur_overlap_area = 0.0;
		aur_overlap_vol = 0.0;
		for ( inew=1; inew<=N_annuli[$1]; inew++ ) {
			aann = sill_area[$1] / N_annuli[$1];
			anew = inew * aann;
			rnew = sqrt(anew / pi);
			ann_aur_vol = aann * sill_thickness[$1][inew] * aureole_thickness_scaled[$1][inew];
			
			
			ann_aur_overlap_vol_min = 0.0; 
			ann_aur_overlap_vol_tot = 0.0; 
			prob_factor_vol = 1.0;
			prob_factor_area = 1.0;
			for ( ino=1; ino<=n_overlap; ino++ ) {
				j = jj[ino];
				d = dd[ino];
				
				
				ann_aur_overlap_area = 0.0;
				ann_aur_overlap_vol = 0.0;				
				for ( iold=1; iold<=N_annuli[j]; iold++ ) {
					aold = iold * sill_area[j] / N_annuli[$1];
					rold = sqrt(aold / pi);
					
# FULL OVERLAP AREA INSIDE EACH NEW-OLD SUB-RADIUS PAIR
# CASE 1: ONE SUB-SILL COMPLETELY INSIDE THE OTHER
# CASE 2: SUB-SILLS INTERSECT IN A LENS-SHAPED REGION
# CASE 3: SUB-SILLS DO NOT INTERSECT

					if (d <= abs(rold-rnew) ) {		
						lens_area = (rnew < rold) ? anew : aold;
					} else if ( d > abs(rold-rnew) && d < (rold+rnew) ) {
						lens_area = intersection_area(d,rnew,rold);
					} else {
						lens_area = 0.0;
					}
					full_overlap_area[inew][ino][iold] = lens_area;
					
# SURFACE AREA OVERLAP OF EACH NEW-OLD SUB-SILL ANNULUS					
					
					if ( full_overlap_area[inew][ino][iold] > 0 ) {
						ann_overlap_area = full_overlap_area[inew][ino][iold];
						if ( iold > 1 ) ann_overlap_area -= full_overlap_area[inew][ino][iold-1];
						if ( inew > 1 ) ann_overlap_area -= full_overlap_area[inew-1][ino][iold];
						if ( iold > 1 && inew > 1 ) ann_overlap_area += full_overlap_area[inew-1][ino][iold-1];
					} else {
						ann_overlap_area = 0.0;
					}
					ann_aur_overlap_area += ann_overlap_area;

# AUREOLE VOLUME OVERLAP BETWEEN EACH NEW-OLD SUB-SILL ANNULUS

					if ( ann_overlap_area > 0.0 ) {
						if (sill_depth[$1] > sill_depth[j]) {
							z1 = sill_depth[j];
							z2 = sill_depth[$1];
							as1 = 0.5*(sill_thickness[j][iold] * (1.0 + aureole_thickness_scaled[j][iold]));
							as2 = 0.5*(sill_thickness[$1][inew] * (1.0 + aureole_thickness_scaled[$1][inew]));
							s1 = 0.5*sill_thickness[j][iold];
							s2 = 0.5*sill_thickness[$1][inew];
						} else {
							z1 = sill_depth[$1];
							z2 = sill_depth[j];
							as1 = 0.5*(sill_thickness[$1][inew] * (1.0 +  aureole_thickness_scaled[$1][inew]));
							as2 = 0.5*(sill_thickness[j][iold] * (1.0 +  aureole_thickness_scaled[j][iold]));
							s1 = 0.5*sill_thickness[$1][inew];
							s2 = 0.5*sill_thickness[j][iold];
						}
						dz = z2 - z1;
						
#						print z1,as1, z2,as2, z1+as1,z2-as2;
						
						if ( (s2+s1) > dz ) {
							if ( (s2-s1) > dz ) {
								s_overlap = 2.0 * s1;
							} else if ( (as1-as2) > dz ) {
								s_overlap = 2.0 * s2;
							} else {
								s_overlap = s1 + s2 - dz;
							}
						} else {
							s_overlap = 0.0;
						}
						if ( s_overlap < 0.0 ) s_overlap = 0.0;
						s_overlap_perc = s_overlap / sill_thickness[$1][inew];
						
						
						if ( (as2+as1) > dz ) {
							if ( (as2-as1) > dz ) {
								z_overlap = 2.0 * as1;
							} else if ( (as1-as2) > dz ) {
								z_overlap = 2.0 * as2;
							} else {
								z_overlap = as1 + as2 - dz;
							}
						} else {
							z_overlap = 0.0;
						}
						z_overlap -= s_overlap;
						z_overlap_perc = z_overlap / (sill_thickness[$1][inew] * aureole_thickness_scaled[$1][inew]);
						ann_aur_overlap_vol += ann_overlap_area * z_overlap;
					} else {
						z_overlap = 0.0;
						ann_aur_overlap_vol += 0.0;
						ann_aur_overlap_vol_perc += 0.0;
						
					}
					
#					print $1, inew, ino, iold, full_overlap_area[inew][ino][iold] / anew, ann_aur_overlap_area / aann, ann_aur_overlap_vol / ann_aur_vol, z_overlap_perc; 

				}	# END EXISTING SILL LOOP

# SAVE MAXIMUM INDIVIDUAL VOLUME OVERLAP AND TOTAL VOLUME OVERLAP

				if ( ann_aur_overlap_vol_min < ann_aur_overlap_vol ) ann_aur_overlap_vol_min = ann_aur_overlap_vol;
				ann_aur_overlap_vol_tot += ann_aur_overlap_vol;
				prob_factor_vol *= (1.0 - ann_aur_overlap_vol/ann_aur_vol);
				prob_factor_area *= (1.0 - ann_aur_overlap_area/aann);

#				print $1, inew, ino, ann_aur_overlap_area / aann, ann_aur_overlap_vol / ann_aur_vol, prob_factor_vol; 
				
			}	# END N OVERLAPPING SILLS LOOP

# ESTIMATE PROPORTION OF EACH NEW ANNULUS THAT IS OVERLAPPED

			if ( ann_aur_overlap_vol_tot > 0.0 ) {
			
				ann_aur_overlap_vol_final_1 = ann_aur_overlap_vol_min + rand() * (ann_aur_overlap_vol_tot - ann_aur_overlap_vol_min);
				if ( ann_aur_overlap_vol_final_1 > ann_aur_vol ) ann_aur_overlap_vol_final_1 = ann_aur_vol;
				ann_aur_overlap_vol_final_1_perc = ann_aur_overlap_vol_final_1 / ann_aur_vol;
				
				ann_aur_overlap_vol_final_2_perc = 1.0 - prob_factor_vol;
				ann_aur_overlap_vol_final_2 = ann_aur_overlap_vol_final_2_perc * ann_aur_vol;
				ann_aur_overlap_area_final_2_perc = 1.0 - prob_factor_area;
				ann_aur_overlap_area_final_2 = ann_aur_overlap_vol_final_2_perc * aann;			
				
				aur_overlap_vol += ann_aur_overlap_vol_final_2;
				aur_overlap_area += ann_aur_overlap_area_final_2;
#				print $1, inew, ann_aur_overlap_vol_final_1_perc, ann_aur_overlap_vol_final_2_perc;
		

# ADJUST MASS FOR EACH ANNULUS TO RELECT OVERLAP

				m[$1][inew] *= (1.0 - ann_aur_overlap_vol_final_2_perc);
			}
		}	# END NEW SILL ANNULUS LOOP

# PROVINCE OVERLAP

		prov_aur_overlap_vol += aur_overlap_vol;
		prov_aur_overlap_vol_perc = prov_aur_overlap_vol / prov_aur_vol[$1];
		prov_overlap_area += aur_overlap_area;
		prov_overlap_area_perc = prov_overlap_area / prov_area[$1];
		
		
# IF ONE OR MORE SILLS OVERLAP IN PLAN, 
# PROCEED TO WORK OUT VOLUME OF INTERSECTION FOR EACH ANULUS
# RA IS THE RADIUS OF THE NEWLY INTRUDING SILL
#    - RAO IS THE OUTER RADIUS OF THE CURRENT ANNULUS
#    - RAI IS THE INNER RADIUS OF THE CURRENT ANNULUS
# RB IS THE RADIUS OF THE EXISTING, OVERLAPPING SILL
#    - RBO IS THE OUTER RADIUS OF THE CURRENT ANNULUS
#    - RBI IS THE INNER RADIUS OF THE CURRENT ANNULUS
	
#		if ( n_overlap > 0 ) {
#			for ( k=1; k<=n_overlap; k++ ) {
#				j = jj[k];
#				d = dd[k];
#				ra = sill_radius[$1];
#				rb = sill_radius[j];

# FOR EACH EXISTING OVERLAPPING SILL, MAKE 3D MATRIX OF OVERLAP AREAS INSIDE
# EACH SUB-RADIUS


# ONE SILL COMPLETELY INSIDE THE OTHER

#				if (d <= abs(rb-ra) ) {
#					lens_area = (ra < rb) ? pi*ra*ra : pi*rb*rb;

# SILLS INTERSECT

#				} else {
##					chunk1 = (d*d + ra*ra - rb*rb)/( 2.0*d*ra );
##					term1 = ra*ra * acos( chunk1 );
##					chunk2 = (d*d + rb*rb - ra*ra)/( 2.0*d*rb );
##					term2 = rb*rb * acos( chunk2 );
##					chunk3 = (-d+ra+rb) * (d+ra-rb) * (d-ra+rb) * (d+ra+rb);
##					term3 = 0.5*sqrt(chunk3);
##					lens_area = term1 + term2 - term3;
#					lens_area = intersection_area(d,ra,rb);
#				}

# AREA OF OVERLAP IN PLAN VIEW

#				sill_overlap_area += lens_area;
#				if ( sill_overlap_area > sill_area[$1] ) sill_overlap_area = sill_area[$1];
					
# DO THESE SILLS OVERLAP IN DEPTH?

#				if (sill_depth[$1] > sill_depth[j]) {
#					dz = sill_depth[$1] - sill_depth[j];
#					a1 = 0.5*(sill_thickness[j][0] * aureole_thickness_scaled[j][0]);
#					a2 = 0.5*(sill_thickness[$1][0] * aureole_thickness_scaled[$1][0]);
#				} else {
#					dz = sill_depth[j] - sill_depth[$1];
#					a1 = 0.5*(sill_thickness[$1][0] * aureole_thickness_scaled[$1][0]);
#					a2 = 0.5*(sill_thickness[j][0] * aureole_thickness_scaled[j][0]);
#				}
#				if ( (a2+a1) > (z2-z1) ) {
#					if ( (a2-a1) > (z2-z1) ) {
#						z_overlap = 2.0 * a1;
#					} else {
#						z_overlap = a1 + a2 - dz;
#					}
#					z_overlap_perc = z_overlap / (sill_thickness[$1][0] * aureole_thickness_scaled[$1][0]);
#				} else {
#					z_overlap = 0.0;
#					z_overlap_perc = 0.0;
#				}
					
# VOLUME OF OVERLAP

#				sill_overlap_vol += lens_area * z_overlap;
#				if ( sill_overlap_vol > sill_vol[$1] ) sill_overlap_vol = sill_vol[$1];

#		print $1, j, n_overlap, lens_area, z_overlap, sill_overlap_vol, sill_vol[$1];
# END OF OVERLAPPING SILLS LOOP
#			}
# END OF ANY OVERLAPPING SILLS IF STATEMENT
#		}

# CORRECTION FACTOR FOR THIS SILL TO USE WHEN CALCULATING EMISSIONS					
# CUMULATIVE % VOLUME OVERLAP FOR WHOLE PROVINCE
				
#		sill_overlap_area_perc[$1] = sill_overlap_area / sill_area[$1];
#		prov_overlap_area += sill_overlap_area;
#		prov_overlap_area_perc[$1] = prov_overlap_area / prov_area[$1];
#		sill_overlap_vol_perc[$1] = sill_vol[$1]>0 ? sill_overlap_vol/sill_vol[$1] : 0.0;
#		prov_overlap_vol += sill_overlap_vol;
#		prov_overlap_vol_perc[$1] = prov_vol[$1]>0 ? prov_overlap_vol/prov_vol[$1] : 0.0;

# ADJUST MASSES FOR EACH ANNULUS TO RELECT OVERLAP

#		for ( ia=0; ia<=N_annuli[j]; ia++ ) m[$1][ia] *= (1.0 - sill_overlap_vol_perc[$1]);

	} 



# PRINT LIST OF PARAMETERS FOR EACH SILL
# 1. INTRUSION TIME (relative to a reference point in the mantle plume head model)
# 2. TOTAL MASS PER UNIT SURFACE AREA
# 3. TOTAL MASS OF CO2 DEGASSED FROM MAGMA
# 4. MATURATION DECAY TIME
# 5. TIME TO ESTABLISHMENT OF VENT
# 6. TIME TO SOLIDIFICATION OF MAGMA
# 7. TIME AFTER PULSE LEFT PLUME CENTRE
# 8. SILL RECURRENCE TIME
# 9. MAXIMUM PULSE RADIUS
# 10. SILL LOCATION RADIUS
# 11. SILL LOCATION AZIMUTH
# 12. NUMBER OF OVERLAPPING SILLS
# 13. OVERLAPPED PERCENTAGE OF AUREOLE FOOTPRINT, THIS SILL
# 14. OVERLAPPED PERCENTAGE OF AUREOLE VOLUME, THIS SILL
# 15. OVERLAPPED PERCENTAGE OF AUREOLE FOOTPRINT, WHOLE PROVINCE
# 16. OVERLAPPED PERCENTAGE OF AUREOLE VOLUME, WHOLE PROVINCE

	if ($2==$3) print time+d_time, m[$1][0], m_CO2[$1][0], t_decay[$1][0], t_vent[$1], t_solid[$1][0], time, t_rec[$1], radius_max[$1], sill_location_radius[$1], sill_location_azimuth[$1], n_overlap, aur_overlap_area/sill_area[$1], aur_overlap_vol/aur_vol[$1],  prov_overlap_area_perc, prov_aur_overlap_vol_perc 		>"LIP_emission_model.test";
		
#		if ($1 > 10000) exit;

} 

#
# CALCULATE SILL PROVINCE EMISSIONS
#

END{

# CUMULATIVE CARBON MASS EXPELLED FROM THE SILL PROVINCE TO CURRENT TIME STEP

	Mcum = 0;
	Mcum_CH4 = 0;
	Mcum_CO2 = 0;
	Mcum_CO2_lava = 0;		
	delCcum = 0;

	time_prev = 0;
	qmult_CH4_prev = 0;
	qmult_CO2_prev = 0;
	qmult_CO2_lava_prev = 0;

	delC_CO2 = delC_mantle;
	delC_CO2_lava = delC_mantle;

	it_step=1;

# LOOP OVER TIME

### REPLACE WITH TIME LOOP

	time_step = 100.0;
#	if (calculate_province != 0) for (it=1; it<N_sills; it+=it_step) {
	if (calculate_province != 0) for (time_prov=time_step; time_prov<=time_stop; time_prov+=time_step) {


	
#WORK OUT VALUE OF it
# I.E. WHERE WE ARE IN THE SILL LIST

		for (it=1; it<N_sills; it++)
			if ( time_prov < (t_rel0[it+1]-t_rel0[1]) )
				break;

# REFERENCE TIME IS TIME OF INTRUSION OF FIRST SILL
	
		t0 = time_prov;

print it, time_prov, t_rel0[it]-t_rel0[1] >"LIP_emission_model.test3";

		
# INITIATE VARIABLES TO SUM CARBON EMISSIONS ACROSS THE ENIRE SILL PROVINCE
# AT THIS TIME STEP

		qmean_CH4 = 0;
		qmult_CH4 = 0; 
		qmult_CO2 = 0;
#		qmult_CO2_lava = 0;
		Mmult_CH4 = 0;
		Mmult_CO2 = 0;
		Mmult_CO2_lava = 0;
		delCmult = 0;

# LOOP OVER ALL SILLS INTRUDED AT THIS TIME STEP
		
		for (j=1; j<=it; j++){ 

### THIS TIME WILL NEED TO BE RECALCULATED 		
###***	
			if ( j == 1 ) {
				time_sill_init = 0.0
			} else {
				time_sill_init = t_rel0[j-1];
			}
			time = t0 - time_sill_init;

# CARBON ONLY RELEASED IF A VENT HAS FORMED

			if ( time > t_vent[j] ) {

# INITIATE VARIABLES TO SUM CARBON EMISSIONS FOR CURRENT SILL ONLY
			
				q_CH4 = 0;
				M_CH4 = 0;
				m_CH4_t = 0;
				delC_refrac = 0;
				delC_crack = 0;						
				q_CO2 = 0;
				M_CO2 = 0;
				m_CO2_t = 0;

# LOOP OVER SUB-SILLS
# (EACH SILL IS ARTIFICIALLY DIVIDED INTO ANNULI OF EQUAL SURFACE AREA TO ACCOUNT FOR THICKNESS VARIATION)
				
				for ( ia=1; ia<=N_annuli[j]; ia++ ) {

# CARBON FLUX FROM THERMOGENIC METHANE
# IN THIS VERSION WE WANT THE MEAN FLUX OVER THE TIME STEP THAT ENDS AT THE PRESENT TIME
# THIS BEST DETERMINED FROM FINITE DIFFERENCING MASS AT START AND END OF TIME STEP

					time_0 = time - time_step;
					time_1 = time;	
					if ( time_0 > 0 ) {
						m_CH4_annulus_0 = m[j][ia] *( 1.0 - exp( -( time_0/t_decay[j][ia] )^p[j][ia] ) ); 
						m_CH4_annulus_1 = m[j][ia] *( 1.0 - exp( -( time_1/t_decay[j][ia] )^p[j][ia] ) ); 
#						m_CH4_annulus = m_CH4_annulus_1 - m_CH4_annulus_0;
						q_CH4_annulus = (m_CH4_annulus_1 - m_CH4_annulus_0) / time_step;
					} else {
						m_CH4_annulus_1 = m[j][ia] *( 1.0 - exp( -( time_1/t_decay[j][ia] )^p[j][ia] ) ); 
#						m_CH4_annulus = m_CH4_annulus_1;
						q_CH4_annulus = m_CH4_annulus_1 / time_step;
					}
					q_CH4 += q_CH4_annulus; 

# CARBON MASS FROM THERMOGENIC METHANE

					M_CH4 += m[j][ia] *( 1.0 - exp( -( time/t_decay[j][ia] )^p[j][ia] ) ); 

# CARBON ISOTOPE COMPOSITION OF THERMOGENIC METHANE

					if ( time <= t_solid[j][ia] ) {
						delC_crack = (-19.5 - 0.8*log(time)/log(10));
						delC_refrac = (-33.0 - 0.6*log(time)/log(10));	
#				delC_crack = -19.5;
#				delC_refrac = -33.0;	
					} else {
						delC_crack = ( -19.5 - 0.8*log(time)/log(10) -7*(log(time)/log(10) - log(t_solid[j][ia])/log(10)) );
						delC_refrac = ( -33.0 - 0.6*log(time)/log(10) -8.5*(log(time)/log(10) - log(t_solid[j][ia])/log(10)) );
#				delC_crack = -19.5;
#				delC_refrac = -33.0;	
					}
					delC_CH4 = CH4_source[j]*delC_crack + (1-CH4_source[j])*delC_refrac;		
					delCmult += q_CH4_annulus * delC_CH4;


# CARBON FROM CARBON DIOXIDE EXSOLVED FROM SILL MAGMA

					if ( time < t_solid[j][ia] ) {
						q_CO2 += m_CO2[j][ia] / (t_solid[j][ia] - t_vent[j]);
						M_CO2 += time/t_solid[j][ia] * m_CO2[j][ia]; 
					} else {
						q_CO2 += 0.0;
						M_CO2 += m_CO2[j][ia];
					}	

				}

# MEAN FLUX OF CARBON FROM METHANE ACROSS SILL PROVINCE				

				qmean_CH4 += q_CH4 / it;

# TOTAL FLUX AND MASS OF CARBON FROM METHANE ACROSS SILL PROVINCE

				qmult_CH4 += q_CH4;
				Mmult_CH4 += M_CH4;

# CARBON ISOTOPIC COMPOSITION OF THERMOGENIC METHANE OF ONE SILL

				
# TOTAL FLUX AND MASS AND ISOTOPIC COMPOSITION OF CARBON FROM SILL MAGMA DEGASSING ACROSS SILL PROVINCE

				qmult_CO2 += q_CO2;
				Mmult_CO2 += M_CO2;
				delCmult += q_CO2 * delC_CO2;

			}
			
# END OF LOOP OVER ALL SILLS INTRUDED AT THIS TIME STEP
							
		}; 

# 

###***	
		Mmult_CO2_lava = qmult_CO2_lava * t0;
		delCmult += qmult_CO2_lava * delC_CO2_lava;



		qtotal = qmult_CH4 + qmult_CO2 + qmult_CO2_lava;
		if (qtotal != 0) { qfrac_CH4 = qmult_CH4/qtotal } else { qfrac_CH4 = 0 };
		Mtotal = Mmult_CH4 + Mmult_CO2 + Mmult_CO2_lava;

# COMPLETE WEIGHTED AVERAGE CALCULATION FOR CARBON ISOTOPIC COMPOSITION

		if ( qtotal > 0 ) delCmult /= qtotal;
#		if ( qmult_CH4 > 0 ) delCmult /= qmult_CH4;
		if ( Mtotal > 0 ) delCcum =  Mtotal_prev/Mtotal * (delCcum_prev - delCmult) + delCmult;

###***			
#		radius_max = sqrt(mantle_area_flux*(t0+t_0)/aspect_ratio/pi);

###***			
		print t0, background_C_emissions+qtotal, background_C_emissions+qmult_CH4, background_C_emissions+qmult_CO2, background_C_emissions+qmult_CO2_lava, qfrac_CH4, Mtotal, Mmult_CH4, Mmult_CO2, Mmult_CO2_lava, delCcum, delCmult, t_rec[it], t_abs[it], radius_max[it], it, qmean_CH4;


# 1.  Time relative to first sill
# 2.  Total carbon flux at this time step
# 3.  Carbon flux from thermogenic methane at this time step
# 4.  Carbon flux from CO2 degassed from sill magma at this time step
# 5.  Carbon flux from CO2 degassed from lavas at this time step
# 6.  Fraction of total carbon supplied as thermogenic methane at this time step
# 7.  Total cumulative carbon mass up to this time
# 8.  Carbon mass from thermogenic methane up to this time
# 9.  Carbon mass from CO2 degassed from sill magma up to this time
# 10.  Carbon mass from CO2 degassed from lavas up to this time
# 11.  Cumulative Carbon isotope composition of all carbon emitted from province
# 12.  Carbon isotope composition of thermogenic+mantle emissions at this time step
# 13.  Sill recurrence time
# 14.  Absolute age
# 15.  Long radius of mantle thermal anomaly marker
# 16.  Time step number (= sill number)
# 17.  Mean carbon flux from thermogenic methane at this time step



		delCcum_prev = delCcum;
		Mtotal_prev = Mtotal;
	} 
}


#
# THESE VARIOUS MODELS FOR CHANGE IN AREA WITH RADIUS
# WERE DETERMINED IN areas.gmt AND time_area.gmt
#

function dadr_ellipse_chain_72( R ) {
nmax = 18;
r[1] = 50; dadr[1] = 0.0;
r[2] = 100; dadr[2] = 136.397;
r[3] = 200; dadr[3] = 306.004;
r[4] = 300; dadr[4] = 455.191;
r[5] = 400; dadr[5] = 437.676;
r[6] = 500; dadr[6] = 482.34;
r[7] = 600; dadr[7] = 631.9;
r[8] = 700; dadr[8] = 584.09;
r[9] = 800; dadr[9] = 497.58;
r[10] = 900; dadr[10] = 595.52;
r[11] = 1000; dadr[11] = 612.95;
r[12] = 1100; dadr[12] = 486.99;
r[13] = 1200; dadr[13] = 458.11;
r[14] = 1300; dadr[14] = 330.86;
r[15] = 1400; dadr[15] = 133.21;
r[16] = 1500; dadr[16] = 70.67;
r[17] = 1750; dadr[17] = 0.964;
r[18] = 2000; dadr[18] =  0.0;
if ( R >= r[nmax] ) exit;
n = 0;
do {n++} while (r[n] <= R);
return dadr[n-1] + (dadr[n]-dadr[n-1]) * (R-r[n-1]) / (r[n]-r[n-1]);
}


function dadr_ellipse_chain_73( R ) {
nmax = 18;
r[1] = 100; dadr[1] = 0.0;
r[2] = 150; dadr[2] = 16.278;
r[3] = 200; dadr[3] = 63.126;
r[4] = 300; dadr[4] = 205.727;
r[5] = 400; dadr[5] = 471.56;
r[6] = 500; dadr[6] = 630.961;
r[7] = 600; dadr[7] = 739.36;
r[8] = 700; dadr[8] = 577.22;
r[9] = 800; dadr[9] = 535.45;
r[10] = 900; dadr[10] = 506.84;
r[11] = 1000; dadr[11] = 560.95;
r[12] = 1100; dadr[12] = 533.6;
r[13] = 1200; dadr[13] = 558.55;
r[14] = 1300; dadr[14] = 429.11;
r[15] = 1400; dadr[15] = 227.39;
r[16] = 1500; dadr[16] = 70.6;
r[17] = 1750; dadr[17] = 34.9;
r[18] = 2000; dadr[18] =  0.0;
if ( R >= r[nmax] ) exit;
n = 0;
do {n++} while (r[n] <= R);
return dadr[n-1] + (dadr[n]-dadr[n-1]) * (R-r[n-1]) / (r[n]-r[n-1]);
}



function dadr_ellipse_deepchain_max_72( R ) {
nmax = 19;
r[1] = 25; dadr[1] = 0.0;
r[2] = 50; dadr[2] = 40.608;
r[3] = 100; dadr[3] = 135.999;
r[4] = 200; dadr[4] = 305.808;
r[5] = 300; dadr[5] = 451.036;
r[6] = 400; dadr[6] = 435.002;
r[7] = 500; dadr[7] = 480.21;
r[8] = 600; dadr[8] =  597.68;
r[9] = 700; dadr[9] =  509.07;
r[10] = 800; dadr[10] =  447.73;
r[11] = 900; dadr[11] =  569.97;
r[12] = 1000; dadr[12] =  658.09;
r[13] = 1100; dadr[13] =  590.79;
r[14] = 1200; dadr[14] =  551.16;
r[15] = 1300; dadr[15] =  332.81;
r[16] = 1400; dadr[16] =  123.45;
r[17] = 1500; dadr[17] =  69.53;
r[18] = 1750; dadr[18] =  5.352;
r[19] = 2000; dadr[19] =  0.0;
if ( R >= r[nmax] ) exit;
n = 0;
do {n++} while (r[n] <= R);
return dadr[n-1] + (dadr[n]-dadr[n-1]) * (R-r[n-1]) / (r[n]-r[n-1]);
}

function dadr_ellipse_deepchain_min_72(R) {
nmax = 18;
r[1] = 50; dadr[1] = 0.0;
r[2] = 100; dadr[2] = 57.809;
r[3] = 200; dadr[3] = 259.56;
r[4] = 300; dadr[4] = 386.546;
r[5] = 400; dadr[5] = 350.029;
r[6] = 500; dadr[6] = 371.19;
r[7] = 600; dadr[7] =  483.54;
r[8] = 700; dadr[8] =  420.26;
r[9] = 800; dadr[9] =  431.07;
r[10] = 900; dadr[10] =  534.14;
r[11] = 1000; dadr[11] =  574.5;
r[12] = 1100; dadr[12] =  447.82;
r[13] = 1200; dadr[13] =  403.05;
r[14] = 1300; dadr[14] =  271.17;
r[15] = 1400; dadr[15] =  99.34;
r[16] = 1500; dadr[16] =  61.02;
r[17] = 1750; dadr[17] =  5.316;
r[18] = 2000; dadr[18] =  0.0;
if ( R >= r[nmax] ) exit;
n = 0;
do {n++} while (r[n] <= R);
return dadr[n-1] + (dadr[n]-dadr[n-1]) * (R-r[n-1]) / (r[n]-r[n-1]);
}

function dadr_ellipse_deepchain_max_82_0(R ) {
nmax = 17;
r[1] = 25; dadr[1] = 0.0;
r[2] = 50; dadr[2] = 40.608;
r[3] = 100; dadr[3] = 135.999;
r[4] = 200; dadr[4] = 245.098;
r[5] = 300; dadr[5] = 260.327;
r[6] = 400; dadr[6] = 154.541;
r[7] = 500; dadr[7] = 172.205;
r[8] = 600; dadr[8] =  254.115;
r[9] = 700; dadr[9] =  138.2;
r[10] = 800; dadr[10] =  66.00;
r[11] = 900; dadr[11] =  63.17;
r[12] = 1000; dadr[12] =  83.56;
r[13] = 1100; dadr[13] =  103.56;
r[14] = 1200; dadr[14] =  73.65;
r[15] = 1300; dadr[15] =  2.62;
r[16] = 1400; dadr[16] =  0.68;
r[17] = 2000; dadr[19] =  0.0;
if ( R >= r[nmax] ) exit;
n = 0;
do {n++} while (r[n] <= R);
return dadr[n-1] + (dadr[n]-dadr[n-1]) * (R-r[n-1]) / (r[n]-r[n-1]);
}

function dadr_ellipse_deepchain_min_82_0(R) {
nmax = 16;
r[1] = 50; dadr[1] = 0.0;
r[2] = 100; dadr[2] = 57.809;
r[3] = 200; dadr[3] = 198.85;
r[4] = 300; dadr[4] = 211.791;
r[5] = 400; dadr[5] = 141.467;
r[6] = 500; dadr[6] = 148.41;
r[7] = 600; dadr[7] =  182.717;
r[8] = 700; dadr[8] =  51.738;
r[9] = 800; dadr[9] =  30.432;
r[10] = 900; dadr[10] =  35.83;
r[11] = 1000; dadr[11] =  39.78;
r[12] = 1100; dadr[12] =  45.16;
r[13] = 1200; dadr[13] =  21.71;
r[14] = 1300; dadr[14] =  2.62;
r[15] = 1400; dadr[15] =  0.69;
r[16] = 1500; dadr[16] =  0.0;
if ( R >= r[nmax] ) exit;
n = 0;
do {n++} while (r[n] <= R);
return dadr[n-1] + (dadr[n]-dadr[n-1]) * (R-r[n-1]) / (r[n]-r[n-1]);
}

function dadr_ellipse_deepchain_min_82_500(R) {
nmax = 18;
r[1] = 50; dadr[1] = 0.0;
r[2] = 100; dadr[2] = 57.809;
r[3] = 200; dadr[3] = 256.171;
r[4] = 300; dadr[4] = 309.487;
r[5] = 400; dadr[5] = 283.164;
r[6] = 500; dadr[6] = 285.124;
r[7] = 600; dadr[7] =  284.59;
r[8] = 700; dadr[8] =  100.29;
r[9] = 800; dadr[9] =  81.23;
r[10] = 900; dadr[10] =  129.88;
r[11] = 1000; dadr[11] =  132.93;
r[12] = 1100; dadr[12] =  113.55;
r[13] = 1200; dadr[13] =  45.67;
r[14] = 1300; dadr[14] =  13.51;
r[15] = 1400; dadr[15] =  20.69;
r[16] = 1500; dadr[16] =  9.76;
r[17] = 1750; dadr[17] =  0.02;
r[18] = 2000; dadr[18] =  0.0;
if ( R >= r[nmax] ) exit;
n = 0;
do {n++} while (r[n] <= R);
return dadr[n-1] + (dadr[n]-dadr[n-1]) * (R-r[n-1]) / (r[n]-r[n-1]);
}


function dadr_ellipse_deepchain_71(R) {
nmax = 15;
r[1] = 0; dadr[1] = 0;
r[2] = 600; dadr[2] =  27.6399;
r[3] = 700; dadr[3] =  119.429;
r[4] = 800; dadr[4] =  172.041;
r[5] = 900; dadr[5] =  172.041;
r[6] = 1000; dadr[6] =  225.347;
r[7] = 1100; dadr[7] =  311.679;
r[8] = 1200; dadr[8] =  485.994;
r[9] = 1300; dadr[9] =  495.57;
r[10] = 1400; dadr[10] =  649.33;
r[11] = 1500; dadr[11] =  667.35;
r[12] = 1700; dadr[12] =  540.755;
r[13] = 2000; dadr[13] =  218.037;
r[14] = 2500; dadr[14] =  0.07;
r[15] = 3000; dadr[15] =  0.0;
if (R>=r[nmax]) exit;
n = 0;
do {n++} while (r[n] <= R);
return dadr[n-1] + (dadr[n]-dadr[n-1]) * (R-r[n-1]) / (r[n]-r[n-1]);
}

function dadr_ellipse_deepchain_70(R) {
nmax = 18;
r[1] = 200; dadr[1] = 0.0;
r[2] = 300; dadr[2] = 33.8166;
r[3] = 400; dadr[3] = 93.6194;
r[4] = 500; dadr[4] = 118.458;
r[5] = 600; dadr[5] =  178.16;
r[6] = 700; dadr[6] =  465.537;
r[7] = 800; dadr[7] =  446.219;
r[8] = 900; dadr[8] =  159.14;
r[9] = 1000; dadr[9] =  123.6;
r[10] = 1100; dadr[10] =  231.23;
r[11] = 1200; dadr[11] =  307.43;
r[12] = 1300; dadr[12] =  458.04;
r[13] = 1400; dadr[13] =  791.69;
r[14] = 1500; dadr[14] =  623.28;
r[15] = 1700; dadr[15] =  298.895;
r[16] = 2000; dadr[16] =  84.2033;
r[17] = 2500; dadr[17] =  1.946;
r[18] = 3000; dadr[18] =  0.0;
if (R>=r[nmax]) exit;
n = 0;
do {n++} while (r[n] <= R);
return dadr[n-1] + (dadr[n]-dadr[n-1]) * (R-r[n-1]) / (r[n]-r[n-1]);
}

function dadr_circle_min(R) {
nmax = 21;
r[1] = 0; dadr[1] = 0;
r[2] = 40; dadr[2] =  0;
r[3] = 45; dadr[3] =  7.4807;
r[4] = 50; dadr[4] =  30.0127;
r[5] = 60; dadr[5] =  71.2801;
r[6] = 80; dadr[6] =  116.568;
r[7] = 100; dadr[7] =  181.045;
r[8] = 150; dadr[8] =  290.168;
r[9] = 200; dadr[9] =  426.442;
r[10] = 300; dadr[10] =  655.94;
r[11] = 400; dadr[11] =  925.55;
r[12] = 500; dadr[12] =  1162.35;
r[13] = 600; dadr[13] =  1246.78;
r[14] = 700; dadr[14] =  1399.19;
r[15] = 800; dadr[15] =  962.64;
r[16] = 1000; dadr[16] =  850.635;
r[17] = 1200; dadr[17] =  644.385;
r[18] = 1400; dadr[18] =  367.64;
r[19] = 1700; dadr[19] =  5.93333;
r[20] = 2000; dadr[20] =  0;
r[21] = 2500; dadr[21] =  0;
if (R>=r[nmax]) exit;
n = 0;
do {n++} while (r[n] <= R);
return dadr[n-1] + (dadr[n]-dadr[n-1]) * (R-r[n-1]) / (r[n]-r[n-1]);
}

function intersection_area(d,ra,rb) {
	chunk1 = (d*d + ra*ra - rb*rb)/( 2.0*d*ra );
	term1 = ra*ra * acos( chunk1 );
	chunk2 = (d*d + rb*rb - ra*ra)/( 2.0*d*rb );
	term2 = rb*rb * acos( chunk2 );
	chunk3 = (-d+ra+rb) * (d+ra-rb) * (d-ra+rb) * (d+ra+rb);
	term3 = 0.5*sqrt(chunk3);
	return term1 + term2 - term3;
}

function erf(xx) {
	xsq=xx*xx; 
	fopi=1.273239545; 
	ca=0.140012; 
	caxsq=ca*xsq; 
	ce=exp(-xsq*(fopi+caxsq)/(1+caxsq)); 
	cs=sqrt(1-ce); 
	if ( xx >= 0) {return cs} else {return -cs};
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

function acos(x) { 
	return atan2(sqrt(1-x*x), x);
}

function abs(v) {
	return v < 0 ? -v : v;
}
