tmpdir=`bin/hbase org.apache.hadoop.hbase.util.GetJavaProperty java.io.tmpdir`
if [ -n "$tmpdir" ]; then
  echo "removing $tmpdir/hbase-enis"
  rm -rf $tmpdir/hbase-enis
fi
