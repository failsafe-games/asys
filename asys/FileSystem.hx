package asys;

#if nodejs
import js.node.Fs;
import js.node.fs.Stats;
#end
import asys.FileStat;

using tink.CoreApi;

class FileSystem {
	
	#if node

	public static function exists(path: String): Future<Bool> {
		var trigger = Future.trigger();
		Fs.stat(path, function(err, stats)
			trigger.trigger(err == null)
		);
		return trigger.asFuture();
	}

	public static function rename(path: String, newPath: String): Promise<Noise> {
		var trigger = Future.trigger();
		Fs.rename(path, newPath, function(err)
			trigger.trigger(switch err {
				case null: Success(Noise);
				default: Failure(Error.withData(err.message, err));
			})
		);
		return trigger.asFuture();
	}

	public static function stat(path: String): Promise<FileStat> {
		var trigger = Future.trigger();
		Fs.stat(path, function(err, stat: Stats)
			trigger.trigger(switch err {
				case null: Success({
					gid: stat.gid,
					uid: stat.uid,
					atime: stat.atime,
					mtime: stat.mtime,
					ctime: stat.ctime,
					size: Std.int(stat.size),
					dev : stat.dev,
					ino: Std.int(stat.ino),
					nlink: stat.nlink,
					rdev: stat.rdev,
					mode: stat.mode
				});
				default: Failure(Error.withData(err.message, err));
			})
		);
		return trigger.asFuture();
	}

	public static function fullPath(relPath: String): Promise<String> {
		var trigger = Future.trigger();
		Fs.realpath(relPath, function(err: js.Error, path)
			trigger.trigger(switch err {
				case null: Success(path);
				default: Failure(Error.withData(err.message, err));
			})
		);
		return trigger.asFuture();
	}

	public static function absolutePath(relPath: String): String {
		if (haxe.io.Path.isAbsolute(relPath)) return relPath;
		return haxe.io.Path.join([Sys.getCwd(), relPath]);
	}

	public static function isDirectory(path: String): Future<Bool> {
		var trigger = Future.trigger();
		Fs.stat(path, function(err: js.Error, stat: Stats)
			trigger.trigger(switch err {
				case null: stat.isDirectory();
				default: false;
			})
		);
		return trigger.asFuture();
	}

	public static function createDirectory(path: String): Promise<Noise> {
		var trigger = Future.trigger();
		Fs.mkdir(path, function(err: js.Error)
			trigger.trigger(switch err {
				case null: Success(Noise);
				default: Failure(Error.withData(err.message, err));
			})
		);
		return trigger.asFuture();
	}

	public static function deleteFile(path: String): Promise<Noise> {
		var trigger = Future.trigger();
		Fs.unlink(path, function(err: js.Error)
			trigger.trigger(switch err {
				case null: Success(Noise);
				default: Failure(Error.withData(err.message, err));
			})
		);
		return trigger.asFuture();
	}

	public static function deleteDirectory(path: String): Promise<Noise> {
		return deleteFile(path);
	}

	public static function readDirectory(path: String): Promise<Array<String>> {
		var trigger = Future.trigger();
		Fs.readdir(path, function(err: js.Error, files)
			trigger.trigger(switch err {
				case null: Success(files);
				default: Failure(Error.withData(err.message, err));
			})
		);
		return trigger.asFuture();
	}
	
	#elseif (tink_runloop && concurrent)
	
	public static function exists(path: String): Future<Bool>
		return Future.async(function(done)
			tink.io.Worker.get().work(function ()
				done(sys.FileSystem.exists(path))
			)
		);

	public static function rename(path: String, newPath: String): Promise<Noise>
		return Future.async(function(done)
			tink.io.Worker.get().work(function () done(
				try {
					sys.FileSystem.rename(path, newPath);
					Success(Noise);
				}
				catch (e: Dynamic) Failure(new Error('$e'))
			))
		);
		
	public static function stat(path: String): Promise<FileStat>
		return Future.async(function(done)
			tink.io.Worker.get().work(function () done(
				try Success(sys.FileSystem.stat(path))
				catch (e: Dynamic) Failure(new Error('$e'))
			))
		);

	public static function fullPath(relPath: String): Promise<String>
		return Future.async(function(done)
			tink.io.Worker.get().work(function () done(
				try Success(sys.FileSystem.fullPath(relPath))
				catch (e: Dynamic) Failure(new Error('$e'))
			))
		);

	public static function absolutePath(relPath: String): String
		return sys.FileSystem.absolutePath(relPath);

	public static function isDirectory(path: String): Future<Bool>
		return Future.async(function(done)
			tink.io.Worker.get().work(function () done(
				try sys.FileSystem.isDirectory(path)
				catch (e: Dynamic) false
			))
		);

	public static function createDirectory(path: String): Promise<Noise> 
		return Future.async(function(done)
			tink.io.Worker.get().work(function () done(
				try {
					sys.FileSystem.createDirectory(path);
					Success(Noise);
				}
				catch (e: Dynamic) Failure(new Error('$e'))
			))
		);

	public static function deleteFile(path: String): Promise<Noise>
		return Future.async(function(done)
			tink.io.Worker.get().work(function () done(
				try {
					sys.FileSystem.deleteFile(path);
					Success(Noise);
				}
				catch (e: Dynamic) Failure(new Error('$e'))
			))
		);

	public static function deleteDirectory(path: String): Promise<Noise> 
		return Future.async(function(done)
			tink.io.Worker.get().work(function () done(
				try {
					sys.FileSystem.deleteDirectory(path);
					Success(Noise);
				}
				catch (e: Dynamic) Failure(new Error('$e'))
			))
		);

	public static function readDirectory(path: String): Promise<Array<String>>
		return Future.async(function(done)
			tink.io.Worker.get().work(function () done(
				try Success(sys.FileSystem.readDirectory(path))
				catch (e: Dynamic) Failure(new Error('$e'))
			))
		);
	
	#else

	public static function exists(path: String): Future<Bool>
		return Future.sync(sys.FileSystem.exists(path));

	public static function rename(path: String, newPath: String): Promise<Noise>
		return Future.sync(
			try {
				sys.FileSystem.rename(path, newPath);
				Success(Noise);
			}
			catch(e: Dynamic) Failure(new Error('$e'))
		);

	public static function stat(path: String): Promise<FileStat>
		return Future.sync(
			try Success(sys.FileSystem.stat(path))
			catch(e: Dynamic) Failure(new Error('$e'))
		);

	public static function fullPath(relPath: String): Promise<String>
		return Future.sync(
			try Success(sys.FileSystem.fullPath(relPath))
			catch(e: Dynamic) Failure(new Error('$e'))
		);

	public static function absolutePath(relPath: String): String
		return sys.FileSystem.absolutePath(relPath);

	public static function isDirectory(path: String): Future<Bool>
		return Future.sync(
			try sys.FileSystem.isDirectory(path)
			catch(e: Dynamic) false
		);

	public static function createDirectory(path: String): Promise<Noise> 
		return Future.sync(
			try {
				sys.FileSystem.createDirectory(path);
				Success(Noise);
			}
			catch(e: Dynamic) Failure(new Error('$e'))
		);

	public static function deleteFile(path: String): Promise<Noise>
		return Future.sync(
			try {
				sys.FileSystem.deleteFile(path);
				Success(Noise);
			}
			catch(e: Dynamic) Failure(new Error('$e'))
		);

	public static function deleteDirectory(path: String): Promise<Noise> 
		return Future.sync(
			try {
				sys.FileSystem.deleteDirectory(path);
				Success(Noise);
			}
			catch(e: Dynamic) Failure(new Error('$e'))
		);

	public static function readDirectory(path: String): Promise<Array<String>>
		return Future.sync(
			try Success(sys.FileSystem.readDirectory(path))
			catch(e: Dynamic) Failure(new Error('$e'))
		);

	#end

}
