#!/bin/bash

tmpd=`mktemp -d`
pushd ${tmpd} >>/dev/null

echo '' > convert.dat

for schema in ${SCHEMAS} ; do
echo include ${SCHEMAD}/${schema} >> convert.dat
done

slaptest -f convert.dat -F .

if [ $? -ne 0 ] ; then
echo "slaptest conversion failed"
exit
fi

for schema in ${SCHEMAS} ; do
fullpath=${SCHEMAD}/${schema}
schema_name=`basename ${fullpath} .schema`
schema_dir=`dirname ${fullpath}`
ldif_file=${schema_name}.ldif

find . -name *${schema_name}.ldif -exec mv '{}' ./${ldif_file} \;
sed -i "/dn:/ c dn: cn=${schema_name},cn=schema,cn=config" ${ldif_file}
sed -i "/cn:/ c cn: ${schema_name}" ${ldif_file}
sed -i '/structuralObjectClass/ d' ${ldif_file}
sed -i '/entryUUID/ d' ${ldif_file}
sed -i '/creatorsName/ d' ${ldif_file}
sed -i '/createTimestamp/ d' ${ldif_file}
sed -i '/entryCSN/ d' ${ldif_file}
sed -i '/modifiersName/ d' ${ldif_file}
sed -i '/modifyTimestamp/ d' ${ldif_file}
sed -i '/^ *$/d' ${ldif_file}

mv ${ldif_file} ${schema_dir}
done

popd >>/dev/null
rm -rf $tmpd
