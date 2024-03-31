Imports System.ComponentModel

Public Class SchedukeTaskTriggerItem
    Implements INotifyPropertyChanged
    Public Event PropertyChanged(sender As Object, e As PropertyChangedEventArgs) Implements INotifyPropertyChanged.PropertyChanged
    Private Sub NotifyPropertyChanged(Optional propertyName As String = "")
        RaiseEvent PropertyChanged(Me, New PropertyChangedEventArgs(propertyName))
    End Sub

    Dim _LoadedDaysOfWeek As Boolean = False
    Public Property LoadedDaysOfWeek As Boolean
        Get
            Return _LoadedDaysOfWeek
        End Get
        Set(value As Boolean)
            _LoadedDaysOfWeek = value
            NotifyPropertyChanged("LoadedDaysOfWeek")
        End Set
    End Property
    Dim _LoadedWeeksOfMonth As Boolean = False
    Public Property LoadedWeeksOfMonth As Boolean
        Get
            Return _LoadedWeeksOfMonth
        End Get
        Set(value As Boolean)
            _LoadedWeeksOfMonth = value
            NotifyPropertyChanged("LoadedWeeksOfMonth")
        End Set
    End Property

    Dim _Sunday As Boolean = False
    Public Property Sunday As Boolean
        Get
            Return _Sunday
        End Get
        Set(value As Boolean)
            _Sunday = value
            NotifyPropertyChanged("Sunday")
        End Set
    End Property
    Dim _Monday As Boolean = False
    Public Property Monday As Boolean
        Get
            Return _Monday
        End Get
        Set(value As Boolean)
            _Monday = value
            NotifyPropertyChanged("Monday")
        End Set
    End Property
    Dim _Tuesday As Boolean = False
    Public Property Tuesday As Boolean
        Get
            Return _Tuesday
        End Get
        Set(value As Boolean)
            _Tuesday = value
            NotifyPropertyChanged("Tuesday")
        End Set
    End Property
    Dim _Wednesday As Boolean = False
    Public Property Wednesday As Boolean
        Get
            Return _Wednesday
        End Get
        Set(value As Boolean)
            _Wednesday = value
            NotifyPropertyChanged("Wednesday")
        End Set
    End Property
    Dim _Thursday As Boolean = False
    Public Property Thursday As Boolean
        Get
            Return _Thursday
        End Get
        Set(value As Boolean)
            _Thursday = value
            NotifyPropertyChanged("Thursday")
        End Set
    End Property
    Dim _Friday As Boolean = False
    Public Property Friday As Boolean
        Get
            Return _Friday
        End Get
        Set(value As Boolean)
            _Friday = value
            NotifyPropertyChanged("Friday")
        End Set
    End Property
    Dim _Saturday As Boolean = False
    Public Property Saturday As Boolean
        Get
            Return _Saturday
        End Get
        Set(value As Boolean)
            _Saturday = value
            NotifyPropertyChanged("Saturday")
        End Set
    End Property

    Dim _First As Boolean = False
    Public Property First As Boolean
        Get
            Return _First
        End Get
        Set(value As Boolean)
            _First = value
            NotifyPropertyChanged("First")
        End Set
    End Property
    Dim _Second As Boolean = False
    Public Property Second As Boolean
        Get
            Return _Second
        End Get
        Set(value As Boolean)
            _Second = value
            NotifyPropertyChanged("Second")
        End Set
    End Property
    Dim _Third As Boolean = False
    Public Property Third As Boolean
        Get
            Return _Third
        End Get
        Set(value As Boolean)
            _Third = value
            NotifyPropertyChanged("Third")
        End Set
    End Property
    Dim _Fourth As Boolean = False
    Public Property Fourth As Boolean
        Get
            Return _Fourth
        End Get
        Set(value As Boolean)
            _Fourth = value
            NotifyPropertyChanged("Fourth")
        End Set
    End Property
    Dim _Last As Boolean = False
    Public Property Last As Boolean
        Get
            Return _Last
        End Get
        Set(value As Boolean)
            _Last = value
            NotifyPropertyChanged("Last")
        End Set
    End Property

    Dim _StartBoundary As String = "2021/1/1 0:00:00"
    Public Property StartBoundary As String
        Get
            Return _StartBoundary
        End Get
        Set(value As String)
            _StartBoundary = value
            NotifyPropertyChanged("StartBoundary")
        End Set
    End Property

End Class
