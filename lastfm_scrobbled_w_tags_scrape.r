start <- strptime("2017-07-24 00:00:00","%Y-%m-%d %H:%M:%S")
end <- strptime("2017-07-30 23:59:59","%Y-%m-%d %H:%M:%S")

start.timestamp <- as.numeric(as.POSIXct(start, origin = '1970-01-01', tz = 'GMT'))
end.timestamp <- as.numeric(as.POSIXct(end, origin = '1970-01-01', tz = 'GMT'))

library(jsonlite)
APIKEY<-"-redacted-"
USERNAME<-"nicoforbessmith"
TIMEZONE<-"Australia/Hobart"

# Due to max limit of 200 tracks scraped at once - must be split into 2 calls
lastfm1 <- fromJSON(paste("https://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks&user=", USERNAME, "&api_key=", APIKEY, "&format=json&limit=200&from=", print(start.timestamp), "&to=", end.timestamp, sep=""))

# I need to automate this - to automatically break calls into 200 track chunks
end.timestamp<-1501033532
lastfm2 <- fromJSON(paste("https://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks&user=", USERNAME, "&api_key=", APIKEY, "&format=json&limit=200&from=", print(start.timestamp), "&to=", end.timestamp, sep=""))


# There is probably a more simple way to do this - I am new to R
lastfm1.simple<-do.call("rbind",jsonlite:::simplify(lastfm$recenttracks, flatten = TRUE))
lastfm1.df <- data.frame(lastfm1.simple)

lastfm2.simple<-do.call("rbind",jsonlite:::simplify(lastfm2$recenttracks, flatten = TRUE))
lastfm2.df <- data.frame(lastfm2.simple)

lastfm1.final<-data.frame(lastfm1.df$name$track, lastfm1.df$artist$track$`#text`, lastfm1.df$artist$track$mbid, lastfm1.df$date$track$uts)
lastfm2.final<-data.frame(lastfm2.df$name$track, lastfm2.df$artist$track$`#text`, lastfm2.df$artist$track$mbid, lastfm2.df$date$track$uts)

colnames(lastfm1.final) <- c('track','artist','artist.mbid','uts')
colnames(lastfm2.final) <- c('track','artist','artist.mbid','uts')

lastfm.final<-rbind(lastfm1.final, lastfm2.final)

lastfm.artists<- unique(data.frame(lastfm.final$artist,lastfm.final$artist.mbid))

library(jsonlite)
lastfm.artists<- unique(data.frame(lastfm.final$artist,lastfm.final$artist.mbid))
artist.tags<-data.frame()

for(i in 1:nrow(lastfm.artists)) {
    artist<-lastfm.artists$lastfm.final.artist[i]
    
    if (lastfm.artists$lastfm.final.artist.mbid[i]=="") {
        request <- fromJSON(paste("http://ws.audioscrobbler.com/2.0/?method=artist.gettoptags&api_key=", APIKEY, "&format=json&artist=", artist, sep=""))
    } else {
        request <- fromJSON(paste("http://ws.audioscrobbler.com/2.0/?method=artist.gettoptags&api_key=", APIKEY, "&format=json&mbid=", lastfm.artists$lastfm.final.artist.mbid[i], sep=""))
    }

    
    if (!is.null(request$toptags$tag$name[1])) {
        tag<-request$toptags$tag$name[1]
    } else {
        tag<-""
    }
    print(paste("artist: ", artist,"tag:",tag, sep = " "))
    artist.tags <- rbind(artist.tags, data.frame(artist=artist, tag=tag))
}

# write artist-tag csv
write.table(artist.tags,"artist.tags.csv",sep=",", row.names=TRUE)

# create final table
lastfm.write.table<-lastfm.final
lastfm.write.table$artist.mbid<-NULL
lastfm.write.table[,3]<-as.POSIXct(as.numeric(as.character(lastfm.write.table[,3])),origin="1970-01-01",tz=TIMEZONE)
lastfm.write.table$day<-weekdays(as.Date(lastfm.write.table[,3]))
lastfm.write.table <- merge(lastfm.write.table,artist.tags.final,by="artist")

# write table to csv
write.table(lastfm.write.table,"lastfm.csv",sep=",", row.names=TRUE)

