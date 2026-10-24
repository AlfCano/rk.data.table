// this code was generated using the rkwarddev package.
// perhaps don't make changes here, but in the rkwarddev script instead!

// define variables globally
    function cleanStr(val) {
        if(!val) return '';
        return val.replace(/'/g, "\\'").replace(/"/g, '\\"');
    }

    function parseVar(fullPath) {
        if (!fullPath) return '';
        var raw_col = '';
        if (fullPath.indexOf('[[') > -1) {
            var parts = fullPath.split('[[');
            var inner = parts[1].replace(']]', '');
            raw_col = inner.replace(/["']/g, '');
        } else if (fullPath.indexOf('$') > -1) {
            raw_col = fullPath.split('$')[1];
        } else {
            raw_col = fullPath;
        }
        return raw_col;
    }
  

function preview(){
	preprocess(true);
	calculate(true);
	printout(true);
}

function preprocess(is_preview){
	// add requirements etc. here
	if(is_preview) {
		echo("if(!base::require(data.table)){stop(" + i18n("Preview not available, because package data.table is not installed or cannot be loaded.") + ")}\n");
	} else {
		echo("require(data.table)\n");
	}
}

function calculate(is_preview){
	// read in variables from dialog


	// the R code to be evaluated

    var data = getValue('reshape_data');
    var mode = getValue('reshape_mode');

    echo('target_data <- data.table::as.data.table(' + data + ')\n');

    if (mode === 'melt') {
        var ids = getValue('melt_id').split('\n').map(parseVar).filter(Boolean);
        var measures = getValue('melt_measure').split('\n').map(parseVar).filter(Boolean);
        var var_name = cleanStr(getValue('melt_varname'));
        var val_name = cleanStr(getValue('melt_valname'));

        var melt_args = ['target_data'];

        // Formatear vectores c('var1', 'var2')
        if (ids.length > 0) melt_args.push('id.vars = c(' + ids.map(function(v){return "'" + v + "'";}).join(', ') + ')');
        if (measures.length > 0) melt_args.push('measure.vars = c(' + measures.map(function(v){return "'" + v + "'";}).join(', ') + ')');

        if (var_name !== '') melt_args.push('variable.name = "' + var_name + '"');
        if (val_name !== '') melt_args.push('value.name = "' + val_name + '"');

        echo('res_dt <- data.table::melt(' + melt_args.join(', ') + ')\n');

    } else {
        var lhs = getValue('dcast_lhs').split('\n').map(parseVar).filter(Boolean);
        var rhs = getValue('dcast_rhs').split('\n').map(parseVar).filter(Boolean);
        var val_var = parseVar(getValue('dcast_val'));
        var fun_agg = getValue('dcast_fun');

        // Construir la fórmula Lado Izquierdo ~ Lado Derecho. Si están vacíos, usar punto (.)
        var lhs_str = lhs.length > 0 ? lhs.map(function(v){return '`' + v + '`';}).join(' + ') : '.';
        var rhs_str = rhs.length > 0 ? rhs.map(function(v){return '`' + v + '`';}).join(' + ') : '.';
        var form_str = lhs_str + ' ~ ' + rhs_str;

        var dcast_args = ['target_data', form_str];

        if (val_var !== '') dcast_args.push('value.var = "' + val_var + '"');
        if (fun_agg !== '') dcast_args.push('fun.aggregate = ' + fun_agg);

        echo('res_dt <- data.table::dcast(' + dcast_args.join(', ') + ')\n');
    }

    // El Preview Nativo (la variable mágica que descubrimos)
    echo('preview_data <- as.data.frame(head(res_dt, 50))\n');
  
}

function printout(is_preview){
	// read in variables from dialog


	// printout the results
	if(!is_preview) {
		new Header(i18n("Reshape (melt & dcast) results")).print();	
	}
    if (typeof is_preview === 'undefined' || !is_preview) {
        echo('rk.header("data.table: Reshape Summary")\n');

        var mode = getValue('reshape_mode');
        var op = (mode === 'melt') ? 'Wide to Long (melt)' : 'Long to Wide (dcast)';

        echo('rk.print(paste("<b>Operation:</b>", "' + op + '", "| <b>New Dimensions:</b>", nrow(res_dt), "rows x", ncol(res_dt), "cols"))\n');

        if (getValue('reshape_save.active')) {
            echo('rk.print(paste0("<b>Object saved as: </b><code>", "' + getValue('reshape_save') + '", "</code>"))\n');
        }
        echo('rk.print("<hr>")\n');
    }
  
	if(!is_preview) {
		//// save result object
		// read in saveobject variables
		var reshapeSave = getValue("reshape_save");
		var reshapeSaveActive = getValue("reshape_save.active");
		var reshapeSaveParent = getValue("reshape_save.parent");
		// assign object to chosen environment
		if(reshapeSaveActive) {
			echo(".GlobalEnv$" + reshapeSave + " <- res_dt\n");
		}	
	}

}

