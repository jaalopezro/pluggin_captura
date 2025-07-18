# -*- coding: utf-8 -*-
"""
/***************************************************************************
 asignacion
                                 A QGIS plugin
 captura
 Generated by Plugin Builder: http://g-sherman.github.io/Qgis-Plugin-Builder/
                              -------------------
        begin                : 2024-04-22
        git sha              : $Format:%H$
        copyright            : (C) 2024 by Jairo Alexander Lopez Rodriguez
        email                : jaalopezro@gmail.com
 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/
"""
from qgis.PyQt.QtCore import QSettings, QTranslator, QCoreApplication
from qgis.PyQt.QtGui import QIcon
from qgis.PyQt.QtWidgets import QAction, QFileDialog

# Initialize Qt resources from file resources.py
from .resources import *
# Import the code for the dialog
from .captura_dialog import asignacionDialog
import os
from dotenv import load_dotenv
import sqlite3
import shutil
import zipfile
from qgis.core import * 
from  qgis.utils import iface
from qgis import analysis
from qgis.analysis import * 
#Importar processing 
import processing
from processing.core.Processing import Processing

load_dotenv(r"C:\Users\jaalo\AppData\Roaming\QGIS\QGIS3\profiles\Tunja_actualizacion\python\plugins\pluggin_git\.env")

pg_dbname = os.getenv("DB_NAME")
pg_user = os.getenv("DB_USER")
pg_password = os.getenv("DB_PASSWORD")
pg_host = os.getenv("DB_HOST")
pg_port = os.getenv("DB_PORT")


class asignacion:
    """QGIS Plugin Implementation."""

    def __init__(self, iface):
        """Constructor.

        :param iface: An interface instance that will be passed to this class
            which provides the hook by which you can manipulate the QGIS
            application at run time.
        :type iface: QgsInterface
        """
        # Save reference to the QGIS interface
        self.iface = iface
        # initialize plugin directory
        self.plugin_dir = os.path.dirname(__file__)
        # initialize locale
        locale = QSettings().value('locale/userLocale')[0:2]
        locale_path = os.path.join(
            self.plugin_dir,
            'i18n',
            'asignacion_{}.qm'.format(locale))

        if os.path.exists(locale_path):
            self.translator = QTranslator()
            self.translator.load(locale_path)
            QCoreApplication.installTranslator(self.translator)
        
        self.dlg=asignacionDialog()
        

        # Declare instance attributes
        self.actions = []
        self.menu = self.tr(u'&asignacion_tunja')

        # Check if plugin was started the first time in current QGIS session
        # Must be set in initGui() to survive plugin reloads
        self.first_start = None

    # noinspection PyMethodMayBeStatic
    def tr(self, message):
        """Get the translation for a string using Qt translation API.

        We implement this ourselves since we do not inherit QObject.

        :param message: String for translation.
        :type message: str, QString

        :returns: Translated version of message.
        :rtype: QString
        """
        # noinspection PyTypeChecker,PyArgumentList,PyCallByClass
        return QCoreApplication.translate('asignacion', message)


    def add_action(
        self,
        icon_path,
        text,
        callback,
        enabled_flag=True,
        add_to_menu=True,
        add_to_toolbar=True,
        status_tip=None,
        whats_this=None,
        parent=None):
        """Add a toolbar icon to the toolbar.

        :param icon_path: Path to the icon for this action. Can be a resource
            path (e.g. ':/plugins/foo/bar.png') or a normal file system path.
        :type icon_path: str

        :param text: Text that should be shown in menu items for this action.
        :type text: str

        :param callback: Function to be called when the action is triggered.
        :type callback: function

        :param enabled_flag: A flag indicating if the action should be enabled
            by default. Defaults to True.
        :type enabled_flag: bool

        :param add_to_menu: Flag indicating whether the action should also
            be added to the menu. Defaults to True.
        :type add_to_menu: bool

        :param add_to_toolbar: Flag indicating whether the action should also
            be added to the toolbar. Defaults to True.
        :type add_to_toolbar: bool

        :param status_tip: Optional text to show in a popup when mouse pointer
            hovers over the action.
        :type status_tip: str

        :param parent: Parent widget for the new action. Defaults None.
        :type parent: QWidget

        :param whats_this: Optional text to show in the status bar when the
            mouse pointer hovers over the action.

        :returns: The action that was created. Note that the action is also
            added to self.actions list.
        :rtype: QAction
        """
        icon = QIcon(icon_path)
        action = QAction(icon, text, parent)
        action.triggered.connect(callback)
        action.setEnabled(enabled_flag)

        if status_tip is not None:
            action.setStatusTip(status_tip)

        if whats_this is not None:
            action.setWhatsThis(whats_this)

        if add_to_toolbar:
            # Adds plugin icon to Plugins toolbar
            self.iface.addToolBarIcon(action)

        if add_to_menu:
            self.iface.addPluginToMenu(
                self.menu,
                action)

        self.actions.append(action)

        return action

    def initGui(self):
        """Create the menu entries and toolear icons inside the QGIS GUI."""

        icon_path = ':/plugins/captura/icon.png'
        self.add_action(
            icon_path,
            text=self.tr(u''),
            callback=self.run,
            parent=self.iface.mainWindow())

        # will be set False in run()
        self.first_start = True


    def unload(self):
        """Removes the plugin menu item and icon from QGIS GUI."""
        for action in self.actions:
            self.iface.removePluginMenu(
                self.tr(u'&asignacion_tunja'),
                action)
            self.iface.removeToolBarIcon(action)


    def run(self):
            
        self.dlg.show ()
        layers = QgsProject.instance().mapLayers().values()
        list_layer= []
        for i in layers:
            list_layer.append(i.name())
        
        self.dlg.layers.clear()       
        self.dlg.layers.addItems(list_layer)
        
        self.dlg.layers_2.clear()       
        self.dlg.layers_2.addItems(list_layer)
        result=self.dlg.exec_()
        
        if result:
            raster =str (self.dlg.layers.currentText())
            terreno =str (self.dlg.layers_2.currentText())
            for lyr in QgsProject.instance().mapLayers().values():
                if  lyr.name()== terreno:
                    terreno=lyr
                    break

        excel = self.dlg.fileWidgetexcel.filePath()
        plantilla = self.dlg.fileWidgetPlantilla.filePath()
        dominios=self.dlg.fileWidgetdominios.filePath()
        geopackage_folder = self.dlg.fileWidgetGeoPackageFolder.filePath()
        plantilla_validaciones=self.dlg.fileWidgetPlantilla_validaciones.filePath()



        processing.run("native:splitvectorlayer",   
                    {'INPUT': terreno,
                        'FIELD':'asignacion',
                        'FILE_TYPE':0,
                        'OUTPUT':geopackage_folder})
        print ("geopaquetes recotados")

        for root, folder, files in os.walk(geopackage_folder):
            for file in files:
                if  file.endswith('.gpkg'): 
                    fullname = os.path.join(root, file) 
                    layer = QgsVectorLayer(fullname)
                    for sublayer in layer.dataProvider().subLayers():
                        tablename = sublayer.split('!!::!!')[1]
                        newname ="lc_terreno"
                        processing.run("native:spatialiteexecutesql", {'DATABASE':fullname,
                            'SQL':'ALTER TABLE {0} RENAME TO {1}'.format(tablename, newname)}) 
                    
        print ("Proceso de cambiar nombre de capa terrenos exitoso")

        for i in os.listdir(geopackage_folder):
            print (i)
            if i.endswith('.gpkg'):
                ruta_archivo = os.path.join(geopackage_folder,i)
                capa = QgsVectorLayer(ruta_archivo + "|layername=lc_terreno")
                ext= capa.extent()
                xmin = ext.xMinimum()-25
                ymin=ext.yMinimum()-25
                xmax=ext.xMaximum()+25
                ymax= ext.yMaximum()+25
                ext= f'{xmin},{xmax},{ymin},{ymax}[EPSG:9377]'
                processing.run("gdal:cliprasterbyextent", 
                    {'INPUT':raster,
                    'PROJWIN': ext,
                    'OVERCRS':False,
                    'NODATA':None,
                    'OPTIONS':'',
                    'DATA_TYPE':0,
                    'EXTRA':'',
                    'OUTPUT':os.path.join(geopackage_folder,i[:-5]+".tiff")}) 
        print("ortofoto cortada con exito")
                        
        for i in os.listdir(geopackage_folder):
            if i.endswith('.gpkg'):
                gpkg_path = os.path.join(geopackage_folder, i)
                recortes = QgsVectorLayer(gpkg_path+"|layername=lc_terreno")
                recortes_ids = [feature['t_id'] for feature in recortes.getFeatures()]
                parametros={
                'INPUT':f"postgres://dbname='{pg_dbname}' host={pg_host} port={pg_port} "
                            f"user='{pg_user}' password='{pg_password}' sslmode=disable " 
                            "key='t_id' checkPrimaryKeyUnicity='1' table=\"tunja_captura\".\"lc_predio\"",
                'EXPRESSION': "lc_terreno IN ('{}')".format("','".join(map(str, recortes_ids))),
                'OUTPUT':"ogr:dbname='{}' table=\"lc_predio\" (geom)".format(gpkg_path)
                }
                processing.run("native:extractbyexpression", parametros)

                

        for i in os.listdir(geopackage_folder):
            if i.endswith('.gpkg'):
                gpkg_path = os.path.join(geopackage_folder, i)
                interesados = QgsVectorLayer(gpkg_path+"|layername=lc_predio")
                lc_predio_ids = [feature['t_id'] for feature in interesados.getFeatures()]
                
                parametros={
                'INPUT':f"postgres://dbname='{pg_dbname}' " f"host={pg_host} " f"port={pg_port} " f"user='{pg_user}' " f"password='{pg_password}' " "sslmode=disable "  "key='t_id' " "checkPrimaryKeyUnicity='1' " 'table="tunja_captura"."lc_interesado"',
                'EXPRESSION': "lc_predio IN ('{}')".format("','".join(map(str, lc_predio_ids))),
                'OUTPUT':"ogr:dbname='{}' table=\"lc_interesado\" (geom)".format(gpkg_path)
                }
                processing.run("native:extractbyexpression", parametros)

        for i in os.listdir(geopackage_folder):
            if i.endswith('.gpkg'):
                gpkg_path = os.path.join(geopackage_folder, i)
                direccion = QgsVectorLayer(gpkg_path+"|layername=lc_terreno")
                lc_terreno_ids = [feature['t_id'] for feature in direccion.getFeatures()]
                
                parametros={
                'INPUT':f"postgres://dbname='{pg_dbname}' " f"host={pg_host} " f"port={pg_port} " f"user='{pg_user}' " f"password='{pg_password}' " "sslmode=disable "  "key='t_id' " "checkPrimaryKeyUnicity='1' " 'table="tunja_captura"."lc_direccion"',
                'EXPRESSION': "lc_terreno IN ('{}')".format("','".join(map(str, lc_terreno_ids))),
                'OUTPUT':"ogr:dbname='{}' table=\"lc_direccion\" (geom)".format(gpkg_path)
                }
                processing.run("native:extractbyexpression", parametros)

        for i in os.listdir(geopackage_folder):
            if i.endswith('.gpkg'):      
                gpkg_path = os.path.join(geopackage_folder, i)         #a partir de aca estoy empaquetando los que no tienen registros o pertenecen a los dominios
                parametros2 = {'LAYERS':[f"postgres://dbname='{pg_dbname}' " f"host={pg_host} " f"port={pg_port} " f"user='{pg_user}' " f"password='{pg_password}' " "sslmode=disable "  "key='t_id' " "checkPrimaryKeyUnicity='1' " 'table="tunja_captura"."archivo"',
                    f"postgres://dbname='{pg_dbname}' " f"host={pg_host} " f"port={pg_port} " f"user='{pg_user}' " f"password='{pg_password}' " "sslmode=disable "  "key='t_id' " "checkPrimaryKeyUnicity='1' " 'table="tunja_captura"."lc_contacto"',
                    f"postgres://dbname='{pg_dbname}' " f"host={pg_host} " f"port={pg_port} " f"user='{pg_user}' " f"password='{pg_password}' " "sslmode=disable "  "key='t_id' " "srid=9377 " "type=PointZ " "checkPrimaryKeyUnicity='1' " 'table="tunja_captura"."lc_unidadconstruccion" (geometria)'],
                'OUTPUT': gpkg_path,
                'OVERWRITE':False,
                'SAVE_STYLES':True,
                'SAVE_METADATA':True,
                'SELECTED_FEATURES_ONLY':False,
                'EXPORT_RELATED_LAYERS':False}
                processing.run("native:package", parametros2)
                print(f"Datos empaquetados en {gpkg_path}")


        for raiz, dirs, archivos in os.walk(geopackage_folder):
            for archivo in archivos:
                if  archivo.endswith('.gpkg'):
                    nombre_completo = os.path.join(raiz, archivo)
                    capa = QgsVectorLayer(nombre_completo, archivo, "ogr")
                    if not capa.isValid():
                        print("¡La capa no se cargó correctamente!")
                        continue
                    # print (capa)
                    for subcapa in capa.dataProvider().subLayers():
                        nombre_subcapa = subcapa.split('!!::!!')[1]
                        sql = 'CREATE TRIGGER {0} AFTER INSERT ON "{0}" BEGIN UPDATE "{0}" SET t_id=new.fid WHERE fid=new.fid;END;'.format(nombre_subcapa.split('!!')[-1])
                        processing.run("native:spatialiteexecutesql", {'DATABASE': nombre_completo, 'SQL': sql})
                       
        print ("trigger creado con exito")

        for i in os.listdir(geopackage_folder):
            if i.endswith('.gpkg'):
                gpkg_path = os.path.join(geopackage_folder, i)
                recortes = QgsVectorLayer(gpkg_path+"|layername=lc_terreno")
                recortes_ids = [feature['t_id'] for feature in recortes.getFeatures()]
                parametros3={
                'INPUT':f"postgres://dbname='{pg_dbname}' host={pg_host} port={pg_port} " f"user='{pg_user}' password='{pg_password}' sslmode=disable "  "key='t_id' checkPrimaryKeyUnicity='1' table=\"tunja_captura\".\"lc_predio\"",
                'EXPRESSION': "lc_terreno IN ('{}')".format("','".join(map(str, recortes_ids))),
                'OUTPUT':"ogr:dbname='{}' table=\"lc_predio_inicial\" (geom)".format(gpkg_path)
                }
                processing.run("native:extractbyexpression", parametros3)
                

        for raiz, dirs, archivos in os.walk(geopackage_folder):
            for archivo in archivos:
                if  archivo.endswith('.gpkg'):
                    nombre_completo = os.path.join(raiz, archivo)
                    capa = QgsVectorLayer(nombre_completo, archivo, "ogr")
                    if not capa.isValid():
                        print("¡La capa no se cargó correctamente!")
                        continue
                    # print (capa)
                    for subcapa in capa.dataProvider().subLayers():
                        nombre_subcapa = subcapa.split('!!::!!')[1]
                        sql = 'UPDATE "{0}" SET fid=t_id'.format(nombre_subcapa.split('!!')[-1])
                        processing.run("native:spatialiteexecutesql", {'DATABASE': nombre_completo, 'SQL': sql})
                       
        print ("update del fid hecho con exito")
        

        archivos = os.listdir(geopackage_folder)


        archivos_por_nombre = {}


        for archivo in archivos:
            nombre, extension = os.path.splitext(archivo)
            if extension == ".gpkg" or extension=='.tiff':
                numero = nombre
                if numero in archivos_por_nombre:
                    archivos_por_nombre[numero].append(archivo)
                else:
                    archivos_por_nombre[numero] = [archivo]
                    

        for llave, archivos in archivos_por_nombre.items():
            carpeta = os.path.join(geopackage_folder,llave[11:])
            if not os.path.exists(carpeta):
                os.makedirs(os.path.join(geopackage_folder,carpeta))

            for archivo in archivos:
                origen = os.path.join(geopackage_folder, archivo) 
                salida = os.path.join(carpeta, archivo)  
                try:
                    os.rename(origen, salida)
                except PermissionError as e:
                    print(f"No se pudo renombrar {origen} debido a: {e}")
                    continue


        archivos=os.listdir(geopackage_folder)

        for carpeta in archivos:
            ruta=os.path.join(geopackage_folder,carpeta)
            if os.path.isdir(ruta):
                archivos_tiff = [archivo for archivo in os.listdir(ruta) if archivo.endswith(".tiff")]
                for archivo_tiff in archivos_tiff:
                    os.rename(os.path.join(ruta,archivo_tiff),os.path.join (ruta,'ortofoto.tiff'))
            if os.path.isdir(ruta):
                archivos_gpkg = [archivo for archivo in os.listdir(ruta) if archivo.endswith(".gpkg")]
                for archivo_gpkg in archivos_gpkg:
                    os.rename(os.path.join(ruta,archivo_gpkg),os.path.join (ruta,'data.gpkg'))
                    

        for i in archivos:
            ruta=os.path.join(geopackage_folder,i)
            shutil.copy(excel,ruta)
            shutil.copy(plantilla,ruta)
            shutil.copy(dominios,ruta)
            shutil.copy(plantilla_validaciones,ruta)

