// Minimal CF/NS <-> Qt type conversions for the bootstrap library.
// The full qcore_foundation.mm pulls in QUrl, QDateTime, QTimeZone etc.
// which are not part of the bootstrap. This file provides only what's needed.

#include <QtCore/qstring.h>
#include <QtCore/qbytearray.h>

#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>

QT_BEGIN_NAMESPACE

// --- QByteArray ---

QByteArray QByteArray::fromCFData(CFDataRef data)
{
    if (!data)
        return QByteArray();
    return QByteArray(reinterpret_cast<const char *>(CFDataGetBytePtr(data)), CFDataGetLength(data));
}

QByteArray QByteArray::fromRawCFData(CFDataRef data)
{
    if (!data)
        return QByteArray();
    return QByteArray::fromRawData(reinterpret_cast<const char *>(CFDataGetBytePtr(data)), CFDataGetLength(data));
}

CFDataRef QByteArray::toCFData() const
{
    return CFDataCreate(kCFAllocatorDefault, reinterpret_cast<const UInt8 *>(data()), length());
}

CFDataRef QByteArray::toRawCFData() const
{
    return CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, reinterpret_cast<const UInt8 *>(data()),
                    length(), kCFAllocatorNull);
}

QByteArray QByteArray::fromNSData(const NSData *data)
{
    if (!data)
        return QByteArray();
    return QByteArray(reinterpret_cast<const char *>([data bytes]), [data length]);
}

QByteArray QByteArray::fromRawNSData(const NSData *data)
{
    if (!data)
        return QByteArray();
    return QByteArray::fromRawData(reinterpret_cast<const char *>([data bytes]), [data length]);
}

NSData *QByteArray::toNSData() const
{
    return [NSData dataWithBytes:constData() length:size()];
}

NSData *QByteArray::toRawNSData() const
{
    return [NSData dataWithBytesNoCopy:const_cast<char *>(constData()) length:size() freeWhenDone:NO];
}

// --- QString ---

QString QString::fromCFString(CFStringRef string)
{
    if (!string)
        return QString();
    CFIndex length = CFStringGetLength(string);
    const UniChar *chars = CFStringGetCharactersPtr(string);
    if (chars)
        return QString(reinterpret_cast<const QChar *>(chars), length);
    QString ret(length, Qt::Uninitialized);
    CFStringGetCharacters(string, CFRangeMake(0, length), reinterpret_cast<UniChar *>(ret.data()));
    return ret;
}

CFStringRef QString::toCFString() const
{
    return QStringView{*this}.toCFString();
}

QString QString::fromNSString(const NSString *string)
{
    if (!string)
        return QString();
    QString qstring;
    qstring.resize([string length]);
    [string getCharacters: reinterpret_cast<unichar*>(qstring.data()) range: NSMakeRange(0, [string length])];
    return qstring;
}

NSString *QString::toNSString() const
{
    return QStringView{*this}.toNSString();
}

// --- QStringView ---

CFStringRef QStringView::toCFString() const
{
    return CFStringCreateWithCharacters(0, reinterpret_cast<const UniChar *>(data()), size());
}

NSString *QStringView::toNSString() const
{
    return [NSString stringWithCharacters:reinterpret_cast<const UniChar*>(data()) length:size()];
}

QT_END_NAMESPACE
